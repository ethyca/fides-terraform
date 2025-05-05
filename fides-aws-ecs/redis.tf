resource "aws_elasticache_subnet_group" "fides_redis" {
  name       = "fides-${var.environment_name}-cache-subnet"
  subnet_ids = [var.fides_primary_subnet, var.fides_alternate_subnet]
}

resource "aws_elasticache_replication_group" "fides_redis" {
  automatic_failover_enabled  = var.elasticache_auto_failover
  auth_token                  = random_password.redis_auth_token.result
  transit_encryption_enabled  = true
  preferred_cache_cluster_azs = [data.aws_subnet.primary.availability_zone]
  replication_group_id        = "rep-group-1-fides-${var.environment_name}"
  subnet_group_name           = aws_elasticache_subnet_group.fides_redis.name
  security_group_ids          = [aws_security_group.redis_sg.id]
  description                 = "fides redis replication group"
  node_type                   = var.elasticache_node_type
  num_cache_clusters          = 1
  port                        = 6379

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.fides_redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.fides_redis.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
}
