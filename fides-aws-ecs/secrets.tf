locals {
  ssm_prefix = "/${trim(var.ssm_parameter_prefix, "/")}/${var.environment_name}"
}

# Fides Secrets

resource "random_password" "fides_encryption_key" {
  length           = 32 # Must be exactly 32 characters.
  special          = true
  override_special = "+/"
}

resource "random_uuid" "fides_oauth_client_id" {}

resource "random_password" "fides_oauth_client_secret" {
  length           = 64
  special          = true
  override_special = "!&#$^<>-"
}

resource "random_password" "fides_drp_jwt_secret" {
  length           = 32
  special          = true
  override_special = "+/"
}

resource "random_password" "fides_root_password" {
  count            = var.fides_root_password == "" ? 1 : 0
  length           = 24
  special          = true
  override_special = "!&#$^<>-"
}

resource "aws_ssm_parameter" "fides_root_password" {
  name        = "${local.ssm_prefix}/fides/root/password"
  description = "The password for the Fides root user."
  type        = "SecureString"
  value       = coalesce(var.fides_root_password, random_password.fides_root_password[0].result)
}

resource "aws_ssm_parameter" "fides_encryption_key" {
  name        = "${local.ssm_prefix}/fides/encryptionkey"
  description = "The AES256 encryption key to encrypt the fides database."
  type        = "SecureString"
  value       = random_password.fides_encryption_key.result
}

resource "aws_ssm_parameter" "fides_oauth_client_id" {
  name        = "${local.ssm_prefix}/fides/oauth/clientid"
  description = "The OAuth client ID for Fides"
  type        = "SecureString"
  value       = random_uuid.fides_oauth_client_id.result
}

resource "aws_ssm_parameter" "fides_oauth_client_secret" {
  name        = "${local.ssm_prefix}/fides/oauth/clientsecret"
  description = "The OAuth client secret for Fides."
  type        = "SecureString"
  value       = random_password.fides_oauth_client_secret.result
}

resource "aws_ssm_parameter" "fides_drp_jwt_secret" {
  name        = "${local.ssm_prefix}/fides/drpjwt"
  description = "The encryption key used to generate DRP JWTs."
  type        = "SecureString"
  value       = random_password.fides_drp_jwt_secret.result
}

resource "aws_ssm_parameter" "fides_system_scanner_pixie_api_key" {
  count       = var.fides_system_scanner_pixie_api_key != "" ? 1 : 0
  name        = "${local.ssm_prefix}/fides/systemscanner/pixieapikey"
  description = "The API key for the Fides system scanner."
  type        = "SecureString"
  value       = var.fides_system_scanner_pixie_api_key
}

resource "aws_ssm_parameter" "fides_dictionary_api_key" {
  count       = var.fides_dictionary_api_key != "" ? 1 : 0
  name        = "${local.ssm_prefix}/fides/dictionary/apikey"
  description = "The API key for the Fides dictionary."
  type        = "SecureString"
  value       = var.fides_dictionary_api_key
}

resource "aws_ssm_parameter" "fides_detection_and_discovery_website_monitor_api_key" {
  count       = var.fides_detection_and_discovery_website_monitor_api_key != "" ? 1 : 0
  name        = "${local.ssm_prefix}/fides/detectionanddiscovery/websitemonitor/apikey"
  description = "The API key for the Fides detection and discovery website monitor."
  type        = "SecureString"
  value       = var.fides_detection_and_discovery_website_monitor_api_key
}

# Redis Secrets

resource "random_password" "redis_auth_token" {
  length           = 64
  special          = true
  override_special = "!&#$^<>-"
}

resource "aws_ssm_parameter" "redis_auth_token" {
  name        = "${local.ssm_prefix}/redis/token"
  description = "The auth token for the ${var.environment_name} Fides Redis instance"
  type        = "SecureString"
  value       = random_password.redis_auth_token.result
}

# Postgres Secrets

resource "random_password" "postgres_main" {
  length           = 32
  special          = true
  override_special = "_!#()*&^$"
}

resource "aws_ssm_parameter" "postgres_password" {
  name        = "${local.ssm_prefix}/database/password"
  description = "The password for the Fides ${var.environment_name} Postgres database"
  type        = "SecureString"
  value       = random_password.postgres_main.result
}

# Docker registry credentials
resource "aws_ssm_parameter" "docker_credentials" {
  count = var.docker_credentials.username != "" && var.docker_credentials.password != "" ? 1 : 0

  name        = "${var.ssm_parameter_prefix}/${var.environment_name}/docker-registry-credentials"
  description = "Docker registry credentials"
  type        = "SecureString"
  value = jsonencode({
    username = var.docker_credentials.username
    password = var.docker_credentials.password
    registry = var.docker_credentials.registry
  })

  tags = {
    Environment = var.environment_name
    Resource    = "Fides"
  }
}

# Docker registry credentials in Secrets Manager for ECS
resource "aws_secretsmanager_secret" "docker_credentials" {
  count = var.docker_credentials.username != "" && var.docker_credentials.password != "" ? 1 : 0

  name        = "docker-registry-credentials-${var.environment_name}"
  description = "Docker registry credentials for ECS"

  tags = {
    Environment = var.environment_name
    Resource    = "Fides"
  }
}

resource "aws_secretsmanager_secret_version" "docker_credentials" {
  count = var.docker_credentials.username != "" && var.docker_credentials.password != "" ? 1 : 0

  secret_id = aws_secretsmanager_secret.docker_credentials[0].id
  secret_string = jsonencode({
    username = var.docker_credentials.username
    password = var.docker_credentials.password
    registry = var.docker_credentials.registry
  })
}

