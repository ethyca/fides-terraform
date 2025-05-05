# We'll only use Cloudfront if custom domain names are used.
locals {
  privacy_center_cloudfront_origin_id     = "privacy-center-${var.environment_name}"
  fides_cloudfront_origin_id              = "fides-${var.environment_name}"
  minimum_cloudfront_tls_protocol_version = "TLSv1.2_2021"
  privacy_center_cloudfront_certificate   = local.use_custom_domain_names == 1 ? aws_acm_certificate_validation.privacy_center_cloudfront_validation[0].certificate_arn : null
  fides_cloudfront_certificate            = local.use_custom_domain_names == 1 ? aws_acm_certificate_validation.fides_cloudfront_validation[0].certificate_arn : null
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

resource "aws_cloudfront_origin_request_policy" "privacy_center_cdn_origin" {
  count   = local.use_custom_domain_names
  name    = "fides-cdn-origin-request-policy-${var.environment_name}"
  comment = "Include all CloudFront Geolocation headers (Address, Country, etc.), query strings, and cookies. Used for Fides Cloud APIs."

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"

    headers {
      items = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "CloudFront-Viewer-Country",
        "CloudFront-Viewer-Country-Name",
        "CloudFront-Viewer-Country-Region",
        "CloudFront-Viewer-Country-Region-Name",
        "Origin",
        "Next-Router-State-Tree",
        "Next-Url",
        "RSC"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

data "aws_cloudfront_origin_request_policy" "allviewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_cache_policy" "privacy_center_cdn_cache" {
  count   = local.use_custom_domain_names
  name    = "fides-cdn-cache-policy-${var.environment_name}"
  comment = "Include geolocation headers (Country & Region) and query strings in the cache key, to cache fides.js bundle by region."

  min_ttl     = 1
  max_ttl     = 86400
  default_ttl = 3600 # default cache to 1 hour

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"

      headers {
        items = [
          "CloudFront-Viewer-Country",
          "CloudFront-Viewer-Country-Region",
        ]
      }
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_cache_policy" "fides_cdn_gvl_translations_cache" {
  count   = var.fides_consent_tcf.tcf_enabled && local.use_custom_domain_names == 1 ? 1 : 0
  name    = "fides-cdn-cache-gvl-translations-policy-${var.environment_name}"
  comment = "Include query strings in the cache key to cache."

  min_ttl     = 1
  max_ttl     = 86400
  default_ttl = 3600 # default cache to 1 hour

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "all"
    }
  }
}

resource "aws_cloudfront_distribution" "privacy_center_distribution" {
  count = local.use_custom_domain_names
  origin {
    domain_name = aws_lb.privacy_center_lb.dns_name
    origin_id   = local.privacy_center_cloudfront_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = compact([
    local.privacy_center_domain,
    var.custom_domain_points_to_cdn ? var.custom_domain : ""
  ])

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = local.privacy_center_cloudfront_origin_id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = aws_cloudfront_cache_policy.privacy_center_cdn_cache[0].id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.privacy_center_cdn_origin[0].id
  }

  # See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html for more information
  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = local.privacy_center_cloudfront_certificate
    minimum_protocol_version = local.minimum_cloudfront_tls_protocol_version
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_acm_certificate_validation.privacy_center_cloudfront_validation
  ]
}

resource "aws_cloudfront_distribution" "fides_distribution" {
  count = local.use_custom_domain_names
  origin {
    domain_name = aws_lb.fides_lb.dns_name
    origin_id   = local.fides_cloudfront_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = compact([
    local.fides_domain,
    var.custom_domain_points_to_cdn ? var.custom_domain : ""
  ])

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"] # These are the minimum allowed cached methods.
    default_ttl              = 0               # Disable caching
    target_origin_id         = local.fides_cloudfront_origin_id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id # Disable Caching
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.allviewer.id
  }

  # enable caching for GVL translations
  dynamic "ordered_cache_behavior" {
    for_each = var.fides_consent_tcf.tcf_enabled ? [1] : []

    content {
      path_pattern             = "/api/v1/privacy-experience/gvl/translations"
      allowed_methods          = ["GET", "HEAD"]
      cached_methods           = ["GET", "HEAD"]
      target_origin_id         = local.fides_cloudfront_origin_id
      compress                 = true
      viewer_protocol_policy   = "redirect-to-https"
      cache_policy_id          = aws_cloudfront_cache_policy.fides_cdn_gvl_translations_cache[0].id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.allviewer.id
    }
  }

  # See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html for more information
  price_class = "PriceClass_100"

  viewer_certificate {
    acm_certificate_arn      = local.fides_cloudfront_certificate
    minimum_protocol_version = local.minimum_cloudfront_tls_protocol_version
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  depends_on = [
    aws_acm_certificate_validation.fides_cloudfront_validation
  ]
}

resource "aws_cloudfront_monitoring_subscription" "privacy_center_monitoring_subscription" {
  count           = local.use_custom_domain_names
  distribution_id = aws_cloudfront_distribution.privacy_center_distribution[0].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}

resource "aws_cloudfront_monitoring_subscription" "fides_monitoring_subscription" {
  count           = local.use_custom_domain_names
  distribution_id = aws_cloudfront_distribution.fides_distribution[0].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}
