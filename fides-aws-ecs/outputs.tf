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
  description = "The primary enpoint for the Fides Redis instance."
  value       = aws_elasticache_replication_group.fides_redis.primary_endpoint_address
}

output "elasticache_arn" {
  description = "The primary enpoint for the Fides Redis instance."
  value       = aws_elasticache_replication_group.fides_redis.arn
}
