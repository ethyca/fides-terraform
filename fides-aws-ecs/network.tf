data "aws_subnet" "primary" {
  id = var.fides_primary_subnet
}

data "aws_subnet" "alternate" {
  id = var.fides_alternate_subnet

  lifecycle {
    postcondition {
      condition     = self.availability_zone != data.aws_subnet.primary.availability_zone
      error_message = "availability_zone must differ from the availabilty_zone of the primary subnet."
    }

    postcondition {
      condition     = self.vpc_id == data.aws_subnet.primary.vpc_id
      error_message = "vpc_id must match the vpc_id of the primary subnet."
    }
  }
}

locals {
  vpc_id = data.aws_subnet.primary.vpc_id
}

resource "aws_eip" "fides_eip" {
  domain = "vpc"
}

# Web server security group
resource "aws_security_group" "web_server_sg" {
  name        = "fides-web-server-${var.environment_name}-sg"
  description = "Security group for Fides web server"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "Fides Web Server port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Privacy center security group
resource "aws_security_group" "privacy_center_sg" {
  name        = "privacy-center-${var.environment_name}-sg"
  description = "Security group for Privacy Center"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "Privacy Center port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Worker security group
resource "aws_security_group" "worker_sg" {
  name        = "fides-worker-${var.environment_name}-sg"
  description = "Security group for Fides worker"
  vpc_id      = local.vpc_id

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Database security group
resource "aws_security_group" "db_sg" {
  name        = "fides-db-${var.environment_name}-sg"
  description = "Security group for database"
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow postgres access from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.primary.cidr_block, data.aws_subnet.alternate.cidr_block]
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Redis security group
resource "aws_security_group" "redis_sg" {
  name        = "fides-redis-${var.environment_name}-sg"
  description = "Security group for Redis"
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow Redis access from private subnets"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.primary.cidr_block, data.aws_subnet.alternate.cidr_block]
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "fides-alb-${var.environment_name}-sg"
  description = "Security group for ALB"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  egress {
    description      = "Allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Keep the old security group for backward compatibility
# but we'll gradually replace its usage
resource "aws_security_group" "fides_sg" {
  description = "allow ingress to fides"
  vpc_id      = local.vpc_id

  ingress {
    description = "allow inbound fides and privacy center traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "allow inbound fides and privacy center traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "allow inbound fides and privacy center traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "allow inbound fides and privacy center traffic"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "allow postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.primary.cidr_block, data.aws_subnet.alternate.cidr_block]
    self        = true
  }

  ingress {
    description = "allow redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.primary.cidr_block, data.aws_subnet.alternate.cidr_block]
    self        = true
  }

  egress {
    description      = "allow all egress"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
