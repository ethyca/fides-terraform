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

resource "random_password" "fides_root_password" {
  length           = 24
  special          = true
  override_special = "!&#$^<>-"
}

resource "aws_ssm_parameter" "fides_root_password" {
  name        = "${local.ssm_prefix}/fides/root/password"
  description = "The password for the Fides root user."
  type        = "SecureString"
  value       = random_password.fides_root_password.result
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

resource "aws_ssm_parameter" "postgres_connection_string" {
  name        = "${local.ssm_prefix}/database/connection_string"
  description = "The connection string for the Fides ${var.environment_name} Postgres database"
  type        = "SecureString"
  value       = "postgresql://${aws_db_instance.postgres.username}:${random_password.postgres_main.result}@${aws_db_instance.postgres.address}:${tostring(aws_db_instance.postgres.port)}/${aws_db_instance.postgres.db_name}?sslmode=require"
}
