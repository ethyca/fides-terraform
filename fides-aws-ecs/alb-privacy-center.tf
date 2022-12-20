# Application Load Balancer for Ingress to Privacy Center
resource "aws_lb" "privacy_center_lb" {
  name               = coalesce(var.lb_name, "privacy-center-${var.environment_name}")
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

resource "aws_lb_target_group" "privacy_center" {
  name        = "privacy-center-${var.environment_name}"
  port        = local.container_def_privacy_center[0].portMappings[0].hostPort
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = local.container_def_privacy_center[0].portMappings[0].hostPort
    matcher             = "200-299"
    interval            = 30
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "privacy_center" {
  load_balancer_arn = aws_lb.privacy_center_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.privacy_center.arn
  }
}

resource "aws_lb_listener_rule" "privacy_center" {
  listener_arn = aws_lb_listener.privacy_center.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.privacy_center.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
