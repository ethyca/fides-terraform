locals {
  worker_environment_variables = [
    {
      name  = "FIDES__CELERY__TASK_ALWAYS_EAGER"
      value = "True"
    }
  ]

  # Create a map of worker name to container definition
  worker_container_defs = { for idx, w in var.workers :
    w.name => {
      name  = "fides-worker-${w.name}"
      image = "${var.fides_image}:${var.fides_version}"

      command = concat(
        ["fides", "worker"],
        w.queues != null ? ["--queues", join(",", w.queues)] : [],
        w.exclude_queues != null ? ["--exclude-queues", join(",", w.exclude_queues)] : []
      )

      cpu       = w.cpu
      memory    = w.memory
      essential = true

      portMappings = []

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].name),
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "fides-worker-${w.name}-${var.environment_name}"
        }
      }

      secrets     = local.fides_secrets
      environment = concat(local.fides_environment_variables, var.fides_additional_environment_variables)
    }
  }

  # Generate container definition JSON strings for each worker
  worker_container_json = { for name, container in local.worker_container_defs :
    name => var.docker_credentials.username != "" && var.docker_credentials.password != "" ? (
      jsonencode(
        [
          merge(container, {
            repositoryCredentials = {
              credentialsParameter = aws_secretsmanager_secret.docker_credentials[0].arn
            }
          })
        ]
      )
    ) : jsonencode([container])
  }
}

data "aws_iam_policy_document" "ecs_worker_task_policy" {
  for_each = { for w in var.workers : w.name => w }

  statement {
    sid = "SSMParameterReadAccess"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = flatten([
      for secret in local.fides_secrets : secret.valueFrom
    ])
  }

  statement {
    sid = "LogWriteAccess"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]

    resources = [
      "${
        coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].arn)
      }:log-stream:fides-worker-${each.value.name}-${var.environment_name}*"
    ]
  }

  statement {
    sid = "S3DsrAccess"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.dsr.arn,
      "${aws_s3_bucket.dsr.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "ecs_worker_task_policy" {
  for_each = { for w in var.workers : w.name => w }
  name     = "fides-worker-${each.value.name}-${var.environment_name}-task-policy"
  policy   = data.aws_iam_policy_document.ecs_worker_task_policy[each.key].json
}

data "aws_iam_policy_document" "ecs_worker_execution_policy" {
  for_each = { for w in var.workers : w.name => w }

  statement {
    sid = "SSMReadAccess"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = concat(
      local.worker_container_defs[each.key].secrets[*].valueFrom,
      var.docker_credentials.username != "" && var.docker_credentials.password != "" ? [aws_ssm_parameter.docker_credentials[0].arn] : []
    )
  }

  statement {
    sid = "LogCreateAccess"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].arn)}:*"
    ]
  }

  dynamic "statement" {
    for_each = var.docker_credentials.username != "" && var.docker_credentials.password != "" ? [1] : []
    content {
      sid = "SecretsManagerReadAccess"

      actions = [
        "secretsmanager:GetSecretValue"
      ]

      resources = [
        aws_secretsmanager_secret.docker_credentials[0].arn
      ]
    }
  }
}

resource "aws_iam_policy" "ecs_worker_execution_policy" {
  for_each = { for w in var.workers : w.name => w }
  name     = "fides-worker-${each.value.name}-${var.environment_name}-execution-policy"
  policy   = data.aws_iam_policy_document.ecs_worker_execution_policy[each.key].json
}

resource "aws_iam_role" "ecs_worker_task_role" {
  for_each           = { for w in var.workers : w.name => w }
  name               = "fides-worker-${each.value.name}-${var.environment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role" "ecs_worker_execution_role" {
  for_each           = { for w in var.workers : w.name => w }
  name               = "fides-worker-${each.value.name}-${var.environment_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_worker_task_role_policy_attachment" {
  for_each   = { for w in var.workers : w.name => w }
  role       = aws_iam_role.ecs_worker_task_role[each.value.name].name
  policy_arn = aws_iam_policy.ecs_worker_task_policy[each.value.name].arn
}

resource "aws_iam_role_policy_attachment" "ecs_worker_execution_role_policy_attachment" {
  for_each   = { for w in var.workers : w.name => w }
  role       = aws_iam_role.ecs_worker_execution_role[each.value.name].name
  policy_arn = aws_iam_policy.ecs_worker_execution_policy[each.value.name].arn
}

resource "aws_ecs_service" "fides_worker" {
  for_each                          = { for w in var.workers : w.name => w }
  name                              = "fides-worker-${each.value.name}-${var.environment_name}"
  cluster                           = aws_ecs_cluster.fides.id
  task_definition                   = aws_ecs_task_definition.fides_worker[each.value.name].arn
  health_check_grace_period_seconds = 60
  desired_count                     = 1
  launch_type                       = "FARGATE"
  force_new_deployment              = true

  network_configuration {
    subnets = [var.fides_primary_subnet]
    security_groups = [
      aws_security_group.worker_sg.id,
      aws_security_group.db_sg.id,
      aws_security_group.redis_sg.id
    ]
    assign_public_ip = true
  }

  depends_on = [
    aws_iam_policy.ecs_worker_task_policy,
    aws_iam_policy.ecs_worker_execution_policy
  ]
}

resource "aws_ecs_task_definition" "fides_worker" {
  for_each                 = { for w in var.workers : w.name => w }
  family                   = "fides_worker_${each.value.name}"
  container_definitions    = local.worker_container_json[each.key]
  execution_role_arn       = aws_iam_role.ecs_worker_execution_role[each.key].arn
  task_role_arn            = aws_iam_role.ecs_worker_task_role[each.key].arn
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  requires_compatibilities = ["FARGATE"]
}
