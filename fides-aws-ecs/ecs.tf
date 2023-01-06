data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_ecs_cluster" "fides" {
  name = "fides-${var.environment_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
