resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "fides ${var.environment_name} subnet group"
  subnet_ids = [var.fides_primary_subnet, var.fides_alternate_subnet]

  tags = {
    Name = "Fides ${var.environment_name} DB Subnet Group"
  }
}

resource "aws_db_instance" "postgres" {
  db_name                         = coalesce(var.rds_name, "fidesdb${title(var.environment_name)}")
  allocated_storage               = var.rds_allocated_storage
  apply_immediately               = true
  engine                          = "postgres"
  engine_version                  = var.rds_postgres_version
  instance_class                  = var.rds_instance_class
  username                        = "fides_user"
  password                        = random_password.postgres_main.result
  skip_final_snapshot             = true
  final_snapshot_identifier       = "test"
  multi_az                        = var.rds_multi_az
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  db_subnet_group_name            = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids          = [aws_security_group.fides_sg.id]
}
