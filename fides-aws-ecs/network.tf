data "aws_subnet" "primary" {
  id = var.fides_primary_subnet
}

data "aws_subnet" "alternate" {
  id = var.fides_alternate_subnet

  lifecycle {
    precondition {
      condition     = var.fides_alternate_subnet != var.fides_primary_subnet
      error_message = "id cannot match the id of the primary subnet."
    }

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
  vpc = true
}

resource "aws_security_group" "fides_sg" {
  description = "allow ingress to fides"
  vpc_id      = local.vpc_id

  ingress {
    description = "allow inbound fides traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    description = "allow postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
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
