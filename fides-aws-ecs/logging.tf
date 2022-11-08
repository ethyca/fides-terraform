resource "aws_cloudwatch_log_group" "fides_ecs" {
  count       = var.cloudwatch_log_group != "" ? 0 : 1
  name_prefix = "/fides/${var.environment_name}/ecs"
}

resource "aws_cloudwatch_log_group" "fides_redis" {
  name_prefix = "/fides/${var.environment_name}/redis"
}

resource "aws_cloudwatch_log_group" "fides_rds" {
  name_prefix = "/fides/${var.environment_name}/rds"
}
