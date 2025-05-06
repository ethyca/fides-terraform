locals {
  use_custom_domain_names = var.route53_config == null ? 0 : 1
  fides_domain            = local.use_custom_domain_names == 1 ? var.route53_config.fides_subdomain : ""
  privacy_center_domain   = local.use_custom_domain_names == 1 ? var.route53_config.privacy_center_subdomain : ""
  fides_url               = local.use_custom_domain_names == 1 ? local.fides_domain : aws_lb.fides_lb.dns_name
  privacy_center_url      = local.use_custom_domain_names == 1 ? local.privacy_center_domain : aws_lb.privacy_center_lb.dns_name

  # CloudFront certificates need to be in us-east-1 region
  cloudfront_enabled = local.use_custom_domain_names == 1 ? true : false
}

data "aws_route53_zone" "primary_zone" {
  count = local.use_custom_domain_names
  name  = var.route53_config.existing_hosted_zone_name
}

# CloudFront certificates (must be in us-east-1)

resource "aws_acm_certificate" "privacy_center_cloudfront" {
  count             = local.use_custom_domain_names
  provider          = aws.us_east_1
  domain_name       = local.privacy_center_domain
  validation_method = "DNS"

  subject_alternative_names = var.custom_domain_points_to_cdn && var.custom_domain != "" ? [var.custom_domain] : []
}

resource "aws_route53_record" "privacy_center_cloudfront_validations" {
  for_each = {
    for dvo in local.use_custom_domain_names == 1 ? aws_acm_certificate.privacy_center_cloudfront[0].domain_validation_options : [] : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "privacy_center_cloudfront_validation" {
  count                   = local.use_custom_domain_names
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.privacy_center_cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.privacy_center_cloudfront_validations : record.fqdn]
}

resource "aws_acm_certificate" "fides_cloudfront" {
  count             = local.use_custom_domain_names
  provider          = aws.us_east_1
  domain_name       = local.fides_domain
  validation_method = "DNS"

  subject_alternative_names = var.custom_domain_points_to_cdn && var.custom_domain != "" ? [var.custom_domain] : []
}

resource "aws_route53_record" "fides_cloudfront_validations" {
  for_each = {
    for dvo in local.use_custom_domain_names == 1 ? aws_acm_certificate.fides_cloudfront[0].domain_validation_options : [] : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "fides_cloudfront_validation" {
  count                   = local.use_custom_domain_names
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.fides_cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.fides_cloudfront_validations : record.fqdn]
}

# Fides

resource "aws_route53_record" "fides" {
  count   = local.use_custom_domain_names
  zone_id = data.aws_route53_zone.primary_zone[0].zone_id
  name    = local.fides_domain
  type    = "A"

  alias {
    name                   = local.cloudfront_enabled ? aws_cloudfront_distribution.fides_distribution[0].domain_name : aws_lb.fides_lb.dns_name
    zone_id                = local.cloudfront_enabled ? aws_cloudfront_distribution.fides_distribution[0].hosted_zone_id : aws_lb.fides_lb.zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.fides_distribution]
}

resource "aws_acm_certificate" "fides_cert" {
  count             = local.use_custom_domain_names
  domain_name       = local.fides_domain
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
  name    = local.privacy_center_domain
  type    = "A"

  alias {
    name                   = local.cloudfront_enabled ? aws_cloudfront_distribution.privacy_center_distribution[0].domain_name : aws_lb.privacy_center_lb.dns_name
    zone_id                = local.cloudfront_enabled ? aws_cloudfront_distribution.privacy_center_distribution[0].hosted_zone_id : aws_lb.privacy_center_lb.zone_id
    evaluate_target_health = true
  }

  depends_on = [aws_cloudfront_distribution.privacy_center_distribution]
}

resource "aws_acm_certificate" "privacy_center_cert" {
  count             = local.use_custom_domain_names
  domain_name       = local.privacy_center_domain
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
