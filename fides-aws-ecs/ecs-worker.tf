locals {
  worker_environment_variables = [
    {
      name  = "FIDES__CELERY__TASK_ALWAYS_EAGER"
      value = "True"
    }
  ]

  worker_container_def = [
    {
      name      = "fides-worker"
      image     = "${var.fides_image}:${var.fides_version}"
      cpu       = var.fides_cpu
      memory    = var.fides_memory
      essential = true

      portMappings = []

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].name),
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "fides-worker-${var.environment_name}"
        }
      }

      secrets     = local.fides_secrets
      environment = concat(local.fides_environment_variables, var.fides_additional_environment_variables)
    }
  ]
}

data "aws_iam_policy_document" "ecs_worker_task_policy" {
  statement {
    sid = "SSMParameterReadAccess"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = local.worker_container_def[0].secrets[*].valueFrom
  }

  statement {
    sid = "LogWriteAccess"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]

    resources = [
      "${coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].arn)}:log-stream:${local.worker_container_def[0].logConfiguration.options.awslogs-stream-prefix}*"
    ]
  }
}

resource "aws_iam_policy" "ecs_worker_task_policy" {
  name   = "fides-worker-${var.environment_name}-policy"
  policy = data.aws_iam_policy_document.ecs_worker_task_policy.json
}

resource "aws_iam_role" "ecs_worker_role" {
  name               = "fides-worker-${var.environment_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_worker_role_policy_attachment" {
  role       = aws_iam_role.ecs_worker_role.name
  policy_arn = aws_iam_policy.ecs_worker_task_policy.arn
}

resource "aws_ecs_service" "fides_worker" {
  name                              = "fides-worker-${var.environment_name}"
  cluster                           = aws_ecs_cluster.fides.id
  task_definition                   = aws_ecs_task_definition.fides_worker.arn
  health_check_grace_period_seconds = 60
  desired_count                     = 1
  launch_type                       = "FARGATE"
  force_new_deployment              = true

  network_configuration {
    subnets          = [var.fides_primary_subnet]
    security_groups  = [aws_security_group.fides_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fides.arn
    container_name   = local.container_def[0].name
    container_port   = local.container_def[0].portMappings[0].containerPort
  }

  depends_on = [
    aws_iam_policy.ecs_worker_task_policy
  ]
}

resource "aws_ecs_task_definition" "fides_worker" {
  family                   = "fides_worker"
  container_definitions    = jsonencode(local.worker_container_def)
  execution_role_arn       = aws_iam_role.ecs_worker_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.fides_cpu
  memory                   = var.fides_memory
  requires_compatibilities = ["FARGATE"]
}
