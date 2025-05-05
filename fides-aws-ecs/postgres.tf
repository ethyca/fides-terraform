resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "fides ${var.environment_name} subnet group"
  subnet_ids = [var.fides_primary_subnet, var.fides_alternate_subnet]

  tags = {
    Name = "Fides ${var.environment_name} DB Subnet Group"
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "rds-enhanced-monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_db_instance" "postgres" {
  db_name           = coalesce(var.rds_name, "fidesdb${title(var.environment_name)}")
  apply_immediately = var.rds_apply_immediately

  engine                     = "postgres"
  engine_version             = var.rds_postgres_version
  auto_minor_version_upgrade = true
  instance_class             = var.rds_instance_class

  multi_az               = var.rds_multi_az
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.fides_sg.id]

  username = "fides_user"
  password = random_password.postgres_main.result

  skip_final_snapshot       = false
  final_snapshot_identifier = "fides-${var.environment_name}-postgres-final-snapshot"
  storage_encrypted         = true
  allocated_storage         = var.rds_allocated_storage

  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  monitoring_interval                   = 30
  monitoring_role_arn                   = aws_iam_role.rds_enhanced_monitoring.arn
}
