# General 

variable "environment_name" {
  description = "The environment name or identifier used to delineate separate Fides instances, e.g. qa, production, etc."
  type        = string
  default     = "staging"

  validation {
    condition     = can(regex("[a-zA-Z][a-zA-Z0-9]{0,25}", var.environment_name))
    error_message = "The value of \"var.environment_name\" must contain only alphanumeric characters, begin with a letter, and cannot exceed 25 characters."
  }
}

# AWS Networking

variable "aws_region" {
  description = "The AWS region to which the Fides resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "fides_primary_subnet" {
  description = "The subnet ID of the primary subnet that will contain Fides resources."
  type        = string
}

variable "fides_alternate_subnet" {
  description = "The subnet ID of the alternate subnet that may contain Fides resources. This subnet should be in a different availability zone from \"var.fides_primary_subnet\"."
  type        = string
}

variable "allowed_ips" {
  description = "A list of IP addresses/ranges that are allowed to make inbound requests to the Fidesops API."
  type        = list(string)

  validation {
    condition     = can([for s in var.allowed_ips : cidrnetmask(s)])
    error_message = "Values within the list for \"allowed_ips\" must be valid IP addresses/ranges in CIDR notation."
  }
}

# Fides Configuration

variable "fides_identity_verification" {
  description = "Whether to require subject identity verification for privacy requests."
  type        = bool
  default     = false
}

variable "fides_require_manual_request_approval" {
  description = "Whether to require privacy requests to be approved before processing."
  type        = bool
  default     = false
}

variable "fides_root_user" {
  description = "The root username to create."
  type        = string
  default     = "fidesroot"
}

variable "fides_root_password" {
  description = "The root user password to create. If one is not provided, one will be generated."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = length(var.fides_root_password) >= 12 || length(var.fides_root_password) == 0
    error_message = "the root password must be at least 12 characters long"
  }
}

variable "fides_log_level" {
  description = "The logging level of Fides."
  type        = string
  default     = "INFO"

  validation {
    condition     = length(regexall("^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$", upper(var.fides_log_level))) > 0
    error_message = "the logging level must be one of the following values: \"DEBUG\", \"INFO\", \"WARNING\", \"ERROR\", or \"CRITICAL\""
  }
}

variable "fides_analytics_opt_out" {
  description = "Whether to opt out of the collection of anonymous analtics."
  type        = bool
  default     = false
}

variable "fides_additional_environment_variables" {
  description = "Additional environment variables to be passed to the container."
  type = list(object({
    name  = string,
    value = string
  }))
  sensitive = true
  default   = []

  validation {
    condition = length(var.fides_additional_environment_variables) == 0 || alltrue([
      for x in var.fides_additional_environment_variables : !contains([
        "FIDES__DATABASE__USER",
        "FIDES__DATABASE__PASSWORD",
        "FIDES__DATABASE__SERVER",
        "FIDES__DATABASE__PORT",
        "FIDES__DATABASE__DB",
        "FIDES__EXECUTION__REQUIRE_MANUAL_REQUEST_APPROVAL",
        "FIDES__EXECUTION__SUBJECT_IDENTITY_VERIFICATION_REQUIRED",
        "FIDES__LOGGING__LEVEL",
        "FIDES__REDIS__HOST",
        "FIDES__REDIS__PORT",
        "FIDES__REDIS__PASSWORD",
        "FIDES__REDIS__CONNECTION_URL",
        "FIDES__SECURITY__APP_ENCRYPTION_KEY",
        "FIDES__SECURITY__OAUTH_ROOT_CLIENT_ID",
        "FIDES__SECURITY__OAUTH_ROOT_CLIENT_SECRET",
        "FIDES__SECURITY__ROOT_PASSWORD",
        "FIDES__SECURITY__ROOT_USERNAME",
        "FIDES__USER__ANALYTICS_OPT_OUT"
      ], x.name)
    ])
    error_message = "cannot pass in that environment variable, reserved use"
  }
}

# Fides Resources - ECS Fargate

variable "fides_image" {
  description = "The Fides Docker image to deploy."
  type        = string
  default     = "ethyca/fides"
}

variable "fides_version" {
  description = "The Fides Version to deploy. Must be a valid Docker tag."
  type        = string
  default     = "2.0.0"
}

variable "fides_cpu" {
  description = "The number of CPU units to dedicate to the Fides container."
  type        = number
  default     = 512
}

variable "fides_memory" {
  description = "The amount of memory, in MiB, to dedicate to the Fides container."
  type        = number
  default     = 2048
}

# Load Balancer

variable "lb_name" {
  description = "The name of the load balancer. If one is not provided, one will be generated."
  type        = string
  default     = ""
}

# Postgres

variable "rds_name" {
  description = "The name of the RDS instance. If one is not provided, one will be generated."
  type        = string
  default     = ""
}

variable "rds_postgres_version" {
  description = "The version of the RDS PostgreSQL engine."
  type        = string
  default     = "13.7"
}

variable "rds_multi_az" {
  description = "Configure RDS to use a multi-AZ deployment."
  type        = bool
  default     = false
}

variable "rds_instance_class" {
  description = "The instance class of the RDS instance."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "The amount of storage, in GiB, to assign to the RDS instance."
  type        = number
  default     = 10
}

# Redis

variable "elasticache_node_type" {
  description = "The node type of the Fides Elasticache cluster."
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_auto_failover" {
  description = "Enable automatic failover on the Elasticache cluster."
  type        = bool
  default     = false
}

# SSM Parameter Store

variable "ssm_parameter_prefix" {
  description = "The prefix for AWS SSM Parameter Store entries related to Fides."
  type        = string
  default     = "/fides"
}

# Cloudwatch Logs

variable "cloudwatch_log_group" {
  description = "The ARN of the CloudWatch Logs group to use. If not specified, one will be created."
  type        = string
  default     = ""
}
