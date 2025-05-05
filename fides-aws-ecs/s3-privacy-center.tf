locals {
  config_json_content  = var.privacy_center_configuration_file == null ? file(var.privacy_center_configuration_file) : file("${path.module}/config/privacyCenterConfig.json")
  config_css_file_path = coalesce(var.privacy_center_css_file, "${path.module}/config/privacyCenterConfig.css")
}

resource "aws_s3_bucket" "privacy_center_config" {
  bucket = "${var.s3_bucket_name_prefix}-privacy-center-config-${var.environment_name}"

  tags = {
    Name = "Fides Privacy Center Configuration - ${title(var.environment_name)}"
  }
}

resource "aws_s3_bucket_acl" "privacy_center_config" {
  bucket = aws_s3_bucket.privacy_center_config.id
  acl    = "private"
}

resource "aws_s3_object" "config_json" {
  bucket       = aws_s3_bucket.privacy_center_config.bucket
  key          = "config.json"
  content      = local.config_json_content
  content_type = "application/json"
  etag         = md5(local.config_json_content)

  depends_on = [
    aws_s3_bucket_acl.privacy_center_config
  ]
}

resource "aws_s3_object" "config_css" {
  bucket       = aws_s3_bucket.privacy_center_config.bucket
  key          = "config.css"
  source       = local.config_css_file_path
  content_type = "text/css"
  etag         = filemd5(local.config_css_file_path)

  depends_on = [
    aws_s3_bucket_acl.privacy_center_config
  ]
}
