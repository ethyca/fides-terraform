locals {
  cors = compact(
    distinct(
      concat(
        var.fides_additional_cors_origins,
        [
          "http://${aws_lb.fides_lb.dns_name}",
          "http://${aws_lb.privacy_center_lb.dns_name}",
          local.use_custom_domain_names == 1 ? "https://${var.route53_config.fides_subdomain}.${data.aws_route53_zone.primary_zone[0].name}" : "",
          local.use_custom_domain_names == 1 ? "https://${var.route53_config.privacy_center_subdomain}.${data.aws_route53_zone.primary_zone[0].name}" : ""
        ]
      )
    )
  )
  web_server_environment_variables = [
    {
      name  = "FIDES__CELERY__TASK_ALWAYS_EAGER"
      value = "True"
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
          name      = "FIDES__DATABASE__PASSWORD"
          valueFrom = aws_ssm_parameter.postgres_password.arn
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
          name      = "FIDES__SECURITY__DRP_JWT_SECRET"
          valueFrom = aws_ssm_parameter.fides_drp_jwt_secret.arn
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
        },
        {
          name      = "FIDES__SYSTEM_SCANNER__PIXIE_API_KEY"
          valueFrom = aws_ssm_parameter.fides_system_scanner_pixie_api_key.arn
        },
        {
          name      = "FIDESPLUS__DICTIONARY__DICTIONARY_SERVICE_API_KEY"
          valueFrom = aws_ssm_parameter.fides_dictionary_api_key.arn
        },
        {
          name      = "FIDESPLUS__DETECTION_DISCOVERY__WEBSITE_MONITOR_SERVICE_API_KEY"
          valueFrom = aws_ssm_parameter.fides_detection_and_discovery_website_monitor_api_key.arn
        }
      ]

      environment = concat(local.fides_environment_variables, var.fides_additional_environment_variables)
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

    resources = local.container_def[0].secrets[*].valueFrom
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

resource "aws_iam_policy" "ecs_task_policy" {
  name   = "fides-${var.environment_name}-policy"
  policy = data.aws_iam_policy_document.ecs_task_policy.json
}

resource "aws_iam_role" "ecs_role" {
  name               = "fides-${var.environment_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_role_policy_attachment" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
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
