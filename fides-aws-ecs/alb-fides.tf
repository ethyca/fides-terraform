# Application Load Balancer for Ingress to Fides
resource "aws_lb" "fides_lb" {
  name               = coalesce(var.lb_name, "fides-${var.environment_name}")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false

  # Enable access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "fides-lb"
    enabled = true
  }

  subnet_mapping {
    subnet_id = var.fides_primary_subnet
  }

  subnet_mapping {
    subnet_id = var.fides_alternate_subnet
  }
}

resource "aws_lb_target_group" "fides" {
  name        = "fides-${var.environment_name}"
  port        = local.webserver_container_def[0].portMappings[0].hostPort
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = local.webserver_container_def[0].portMappings[0].hostPort
    matcher             = "200-299"
    interval            = 30
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "fides" {
  load_balancer_arn = aws_lb.fides_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fides.arn
  }
}

resource "aws_lb_listener" "fides_https" {
  count             = local.use_custom_domain_names
  load_balancer_arn = aws_lb.fides_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.fides_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fides.arn
  }
  depends_on = [
    aws_acm_certificate_validation.fides_cert_validation
  ]
}

resource "aws_lb_listener_certificate" "fides_cert" {
  listener_arn    = aws_lb_listener.fides_https[0].arn
  certificate_arn = aws_acm_certificate_validation.fides_cert_validation[0].certificate_arn
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
