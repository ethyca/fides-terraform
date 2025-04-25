locals {
  use_custom_domain_names = var.route53_config == null ? 0 : 1
  fides_url               = local.use_custom_domain_names == 1 ? aws_route53_record.fides[0].name : aws_lb.fides_lb.dns_name
  privacy_center_url      = local.use_custom_domain_names == 1 ? aws_route53_record.privacy_center[0].name : aws_lb.privacy_center_lb.dns_name
}

data "aws_route53_zone" "primary_zone" {
  count = local.use_custom_domain_names
  name  = var.route53_config.existing_hosted_zone_name
}

# Fides

resource "aws_route53_record" "fides" {
  count   = local.use_custom_domain_names
  zone_id = data.aws_route53_zone.primary_zone[0].zone_id
  name    = var.route53_config.fides_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.fides_lb.dns_name
    zone_id                = aws_lb.fides_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "fides_cert" {
  count             = local.use_custom_domain_names
  domain_name       = aws_route53_record.fides[0].name
  validation_method = "DNS"
}

resource "aws_route53_record" "fides_cert_validations" {
  for_each = {
    for dvo in aws_acm_certificate.fides_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary_zone[0].zone_id
}

resource "aws_acm_certificate_validation" "fides_cert_validation" {
  count = local.use_custom_domain_names

  certificate_arn         = aws_acm_certificate.fides_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.fides_cert_validations : record.fqdn]
}

# Privacy Center

resource "aws_route53_record" "privacy_center" {
  count   = local.use_custom_domain_names
  zone_id = data.aws_route53_zone.primary_zone[0].zone_id
  name    = var.route53_config.privacy_center_subdomain
  type    = "A"

  alias {
    name                   = aws_lb.privacy_center_lb.dns_name
    zone_id                = aws_lb.privacy_center_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "privacy_center_cert" {
  count             = local.use_custom_domain_names
  domain_name       = aws_route53_record.privacy_center[0].name
  validation_method = "DNS"
}

resource "aws_route53_record" "privacy_center_validations" {
  for_each = {
    for dvo in aws_acm_certificate.privacy_center_cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary_zone[0].zone_id
}

resource "aws_acm_certificate_validation" "privacy_center_validation" {
  count = local.use_custom_domain_names

  certificate_arn         = aws_acm_certificate.privacy_center_cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.privacy_center_validations : record.fqdn]
}
