# terraform-fides-aws-ecs

This Terraform module creates an instance of [`fides`](./helm-charts/fides/) on AWS ECS with Fargate along with all required peripheral resources, including the Postgres database and Redis cache.

## Usage

### Prerequisites

Before calling this module, you should have a Virtual Private Cloud (VPC) with two subnets in separate availability zones and a hosted zone in Route 53.

### How to call this module

The following code sample illustrates a subset of the available variables. To see all possible variables, refer to the [`variables.tf`](./variables.tf) file.

```hcl
module "fides_aws_ecs" {
  source = "github.com/ethyca/fides-terraform//fides-aws-ecs?depth=1&ref=fides-aws-ecs/v1.0.1"

  environment_name = "production"

  primary_subnet   = "<SUBNET_ID>"
  alternate_subnet = "<SUBNET_ID>"
  allowed_ips      = ["<IP Range in CIDR notation>"] # To make it publicly accessible, add 0.0.0.0/0

  fides_identity_verification           = false
  fides_require_manual_request_approval = true
  fides_log_level                       = "<Logging level>" # Valid values include DEBUG, INFO, WARNING, ERROR, and CRITICAL
  ...
}
```

### Private Docker Images

This module supports using private Docker images from Docker Hub for both Fides and Privacy Center. To use private images:

1. Provide your Docker Hub username and password
2. Optionally specify a custom registry if not using Docker Hub

The module will automatically detect when Docker credentials are provided and enable private registry access. If username or password is empty, public images will be used.
