locals {
  environment_variables = [
    {
      name  = "FIDES__LOGGING__LEVEL"
      value = upper(var.fides_log_level)
    },
    {
      name  = "FIDES__USER__ANALYTICS_OPT_OUT"
      value = tostring(var.fides_analytics_opt_out)
    },
    {
      name  = "FIDES__DATABASE__SERVER"
      value = aws_db_instance.postgres.address
    },
    {
      name  = "FIDES__DATABASE__PORT"
      value = aws_db_instance.postgres.port
    },
    {
      name  = "FIDES__DATABASE__DB"
      value = aws_db_instance.postgres.db_name
    },
    {
      name  = "FIDES__DATABASE__USERNAME"
      value = aws_db_instance.postgres.username
    },
    {
      name  = "FIDES__REDIS__PORT"
      value = tostring(aws_elasticache_replication_group.fides_redis.port)
    },
    {
      name  = "FIDES__REDIS__HOST"
      value = aws_elasticache_replication_group.fides_redis.primary_endpoint_address
    },
    {
      name  = "FIDES__EXECUTION__SUBJECT_IDENTITY_VERIFICATION_REQUIRED"
      value = tostring(var.fides_identity_verification)
    },
    {
      name  = "FIDES__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL"
      value = tostring(var.fides_require_manual_request_approval)
    },
    {
      name  = "FIDES__SECURITY__ROOT_USERNAME"
      value = var.fides_root_user
    }
  ]
  container_def = [
    {
      name      = "fides"
      image     = "${var.fides_image}:${var.fides_version}"
      cpu       = var.fides_cpu
      memory    = var.fides_memory
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].name),
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "fides-${var.environment_name}-ecs"
        }
      }

      secrets = [
        {
          # Need to use the connection string format to pass in the sslMode parameter.
          name      = "FIDES__DATABASE__PASSWORD"
          valueFrom = aws_ssm_parameter.postgres_password
        },
        {
          name      = "FIDES__REDIS__PASSWORD"
          valueFrom = aws_ssm_parameter.redis_auth_token.arn
        },
        {
          name      = "FIDES__SECURITY__APP_ENCRYPTION_KEY"
          valueFrom = aws_ssm_parameter.fides_encryption_key.arn
        },
        {
          name      = "FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID"
          valueFrom = aws_ssm_parameter.fides_oauth_client_id.arn
        },
        {
          name      = "FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET"
          valueFrom = aws_ssm_parameter.fides_oauth_client_secret.arn
        },
        {
          name      = "FIDES__SECURITY__ROOT_PASSWORD"
          valueFrom = aws_ssm_parameter.fides_root_password.arn
        }
      ]

      environment = local.environment_variables
    }
  ]
}

data "aws_iam_policy_document" "ecs_task_policy" {
  statement {
    sid = "0"

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]

    resources = [
      aws_ssm_parameter.postgres_connection_string.arn,
      aws_ssm_parameter.redis_auth_token.arn,
      aws_ssm_parameter.fides_oauth_client_secret.arn,
      aws_ssm_parameter.fides_oauth_client_id.arn,
      aws_ssm_parameter.fides_encryption_key.arn,
      aws_ssm_parameter.fides_root_password.arn
    ]
  }

  statement {
    sid = "1"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]

    resources = [
      "${coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].arn)}*"
    ]
  }
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_task_policy" {
  name   = "fides-${var.environment_name}-policy"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

resource "aws_iam_role" "ecs_role" {
  name                = "fides-${var.environment_name}-role"
  assume_role_policy  = data.aws_iam_policy_document.ecs_task_assume_role.json
  managed_policy_arns = [aws_iam_policy.ecs_task_policy.arn]
}

resource "aws_ecs_cluster" "fides" {
  name = "fides-${var.environment_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "fides" {
  name                              = "fides-${var.environment_name}"
  cluster                           = aws_ecs_cluster.fides.id
  task_definition                   = aws_ecs_task_definition.fides.arn
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
    aws_iam_policy.ecs_task_policy
  ]
}

resource "aws_ecs_task_definition" "fides" {
  family                   = "fides_service"
  container_definitions    = jsonencode(local.container_def)
  execution_role_arn       = aws_iam_role.ecs_role.arn
  network_mode             = "awsvpc"
  cpu                      = var.fides_cpu
  memory                   = var.fides_memory
  requires_compatibilities = ["FARGATE"]
}
