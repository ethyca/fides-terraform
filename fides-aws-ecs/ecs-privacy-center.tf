locals {
  privacy_center_config_path = "/app/config"
  container_def_privacy_center = [
    {
      name      = "privacy-center"
      image     = "${var.privacy_center_image}:${var.privacy_center_version}"
      cpu       = var.privacy_center_cpu
      memory    = var.privacy_center_memory
      essential = true
      user      = "root"
      command = ["/bin/sh", "-c",
        <<-COMMAND
        apk add --no-cache aws-cli sudo \
          && aws s3 cp s3://${aws_s3_bucket.privacy_center_config.bucket}/${aws_s3_object.config_json.id} ${local.privacy_center_config_path}/config.json \
          && aws s3 cp s3://${aws_s3_bucket.privacy_center_config.bucket}/${aws_s3_object.config_css.id} ${local.privacy_center_config_path} \
          && npm run start
        COMMAND
      ]
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "NODE_DISABLE_COLORS"
          value = "1"
        },
        {
          name  = "FIDES_PRIVACY_CENTER__FIDES_API_URL"
          value = "https://${local.fides_url}/api/v1"
        },
        {
          name  = "FIDES_PRIVACY_CENTER__PRIVACY_CENTER_URL"
          value = "https://${local.privacy_center_url}"
        },
        {
          name  = "FIDES_PRIVACY_CENTER__CONFIG_JSON_URL"
          value = "file://${local.privacy_center_config_path}/config.json"
        },
        {
          name  = "FIDES_PRIVACY_CENTER__CONFIG_JSON_CSS"
          value = "file://${local.privacy_center_config_path}/config.css"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].name),
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "privacy-center-${var.environment_name}-ecs"
        }
      }
    }
  ]
}

data "aws_iam_policy_document" "ecs_task_policy_privacy_center" {

  statement {
    sid = "LogWriteAccess"

    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream"
    ]

    resources = [
      "${coalesce(var.cloudwatch_log_group, aws_cloudwatch_log_group.fides_ecs[0].arn)}:log-stream:${local.container_def_privacy_center[0].logConfiguration.options.awslogs-stream-prefix}*"
    ]
  }

  statement {
    sid = "S3ListAccess"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.privacy_center_config.arn
    ]
  }

  statement {
    sid = "S3ObjectAccess"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.privacy_center_config.arn}/${aws_s3_object.config_json.id}",
      "${aws_s3_bucket.privacy_center_config.arn}/${aws_s3_object.config_css.id}"
    ]
  }
}

resource "aws_iam_policy" "ecs_task_policy_privacy_center" {
  name   = "privacy-center-${var.environment_name}-task-policy"
  policy = data.aws_iam_policy_document.ecs_task_policy_privacy_center.json
}

data "aws_iam_policy_document" "ecs_execution_policy_privacy_center" {
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
}

resource "aws_iam_policy" "ecs_execution_policy_privacy_center" {
  name   = "privacy-center-${var.environment_name}-execution-policy"
  policy = data.aws_iam_policy_document.ecs_execution_policy_privacy_center.json
}

resource "aws_iam_role" "ecs_task_role_privacy_center" {
  name               = "privacy_center-${var.environment_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role" "ecs_execution_role_privacy_center" {
  name               = "privacy_center-${var.environment_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "privacy_center_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role_privacy_center.name
  policy_arn = aws_iam_policy.ecs_task_policy_privacy_center.arn
}

resource "aws_iam_role_policy_attachment" "privacy_center_execution_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role_privacy_center.name
  policy_arn = aws_iam_policy.ecs_execution_policy_privacy_center.arn
}

resource "aws_ecs_service" "privacy_center" {
  name                              = "privacy-center-${var.environment_name}"
  cluster                           = aws_ecs_cluster.fides.id
  task_definition                   = aws_ecs_task_definition.privacy_center.arn
  health_check_grace_period_seconds = 60
  desired_count                     = 1
  launch_type                       = "FARGATE"
  force_new_deployment              = true

  network_configuration {
    subnets          = [var.fides_primary_subnet]
    security_groups  = [aws_security_group.privacy_center_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.privacy_center.arn
    container_name   = local.container_def_privacy_center[0].name
    container_port   = local.container_def_privacy_center[0].portMappings[0].hostPort
  }

  depends_on = [
    aws_iam_policy.ecs_task_policy_privacy_center,
    aws_iam_policy.ecs_execution_policy_privacy_center
  ]
}

resource "aws_ecs_task_definition" "privacy_center" {
  family                   = "privacy_center"
  container_definitions    = jsonencode(local.container_def_privacy_center)
  execution_role_arn       = aws_iam_role.ecs_execution_role_privacy_center.arn
  task_role_arn            = aws_iam_role.ecs_task_role_privacy_center.arn
  network_mode             = "awsvpc"
  cpu                      = var.privacy_center_cpu
  memory                   = var.privacy_center_memory
  requires_compatibilities = ["FARGATE"]
}
