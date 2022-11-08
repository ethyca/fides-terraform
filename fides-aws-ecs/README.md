# terraform-fides-aws-ecs

This Terraform module creates an instance of [`fides`](./helm-charts/fides/) on AWS ECS with Fargate along with all required peripheral resources, including the Postgres database and Redis cache.

## How to call this module

```hcl
module "fides_aws_ecs" {
  source = "github.com/ethyca/fides-deployment//terraform/fides-aws-ecs"

  environment_name = "production"

  fides_primary_subnet   = "<SUBNET_ID>"
  fides_alternate_subnet = "<SUBNET_ID>"
  allowed_ips            = ["<IP Range in CIDR notation>"] # To make it publicly accessible, add 0.0.0.0/0

  fides_identity_verification           = false
  fides_require_manual_request_approval = true
  fides_log_level                       = "<Logging level>" # Valid values include TRACE, DEBUG, INFO, WARNING, ERROR, and CRITICAL
}
```