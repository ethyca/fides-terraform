# Fides Outputs

output "fides_root_username" {
  description = "The root Fides user's username."
  value       = var.fides_root_user
}

output "fides_root_password" {
  description = "The root Fides user's password."
  value       = var.fides_root_user
  sensitive   = true
}

# Load Balancer Outputs

output "fides_endpoint" {
  description = "The URL of the Fides load balancer."
  value       = local.fides_url
}

output "privacy_center_endpoint" {
  description = "The URL of the Privacy Center load balancer."
  value       = local.privacy_center_url
}

# Database Outputs

output "postgres_endpoint" {
  description = "The connection endpoint for the Fides Postgres database."
  value       = aws_db_instance.postgres.endpoint
}

output "rds_arn" {
  description = "The ARN of the RDS instance."
  value       = aws_db_instance.postgres.arn
}

# Redis Outputs

output "redis_endpoint" {
  description = "The primary endpoint for the Fides Redis instance."
  value       = aws_elasticache_replication_group.fides_redis.primary_endpoint_address
}

output "elasticache_arn" {
  description = "The primary endpoint for the Fides Redis instance."
  value       = aws_elasticache_replication_group.fides_redis.arn
}
