# Application Load Balancer for Ingress to ECS Fargate
resource "aws_lb" "fides_lb" {
  name               = coalesce(var.lb_name, "fides-${var.environment_name}")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.fides_sg.id]

  enable_deletion_protection = false

  subnet_mapping {
    subnet_id = var.fides_primary_subnet
  }

  subnet_mapping {
    subnet_id = var.fides_alternate_subnet
  }
}

resource "aws_lb_target_group" "fides" {
  name        = "fides-${var.environment_name}"
  port        = local.container_def[0].portMappings[0].containerPort
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = local.container_def[0].portMappings[0].containerPort
    matcher             = "200-299"
    interval            = 30
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "fides" {
  load_balancer_arn = aws_lb.fides_lb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fides.arn
  }
}

resource "aws_lb_listener_rule" "fides" {
  listener_arn = aws_lb_listener.fides.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fides.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
