# Application Load Balancer for Ingress to Privacy Center
resource "aws_lb" "privacy_center_lb" {
  name               = coalesce(var.lb_name, "privacy-center-${var.environment_name}")
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  enable_deletion_protection = false

  # Enable access logs
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "privacy-center-lb"
    enabled = true
  }

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

resource "aws_lb_listener" "privacy_center_https" {
  count             = local.use_custom_domain_names
  load_balancer_arn = aws_lb.privacy_center_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06" // TLS 1.2, see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#tls-security-policies
  certificate_arn   = aws_acm_certificate.privacy_center_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.privacy_center.arn
  }

  depends_on = [
    aws_acm_certificate_validation.privacy_center_validation
  ]
}

resource "aws_lb_listener_certificate" "privacy_center_cert" {
  listener_arn    = aws_lb_listener.privacy_center_https[0].arn
  certificate_arn = aws_acm_certificate_validation.privacy_center_validation[0].certificate_arn
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
