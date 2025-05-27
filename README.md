# Fides Terraform Modules

This repository contains reusable Terraform modules for Fides infrastructure.

## Module Versioning

Each module is versioned independently using a `version.json` file in the module directory. When changes are pushed to the main branch, our CI pipeline automatically tags modules that have updated version numbers.

### Version Format

Tags follow the format `{module-name}/v{version}`, for example: `fides-aws-ecs/v1.0.0`

## Using Modules

To use a module in your Terraform configuration:

```hcl
module "fides_aws_ecs" {
  source = "github.com/ethyca/fides-terraform//fides-aws-ecs?ref=fides-aws-ecs/v1.0.0"

  # Module inputs here
}
```

Note the double slash (`//`) in the source URL, which is required when referencing a subdirectory in a Git repository.

## Available Modules

- **[fides-aws-ecs](./fides-aws-ecs/README.md)**: Deploys Fides on AWS ECS

## Development

### Getting Started

1. Clone the repository
2. Install the Terraform version specified in the `.terraform-version` file
   a. You can use `brew install tfenv` to install [`tfenv`](https://github.com/tfutils/tfenv) if you don't have it already.
   b. You can use `tfenv use` to install the correct version.
3. Run `terraform init` to install the correct version of Terraform providers

### Updating a Module

1. Make your changes to the module
2. Update the `version` field in the module's `version.json` file according to semantic versioning
3. Create a PR and merge to the `main` branch
4. The GitHub Actions workflow will automatically create a tag for the new version

### Module Structure

Each module should include:

- `version.json` - Contains module metadata and version
- `README.md` - Module documentation
- Terraform files, including at least a `main.tf`, `variables.tf`, and `outputs.tf`

## :balance_scale: License

The [Fides](https://github.com/ethyca/fides) ecosystem of tools are licensed under the [Apache Software License Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
Fides tools are built on [fideslang](https://github.com/ethyca/privacy-taxonomy), the Fides language specification, which is licensed under [CC by 4](https://github.com/ethyca/privacy-taxonomy/blob/main/LICENSE).

Fides is created and sponsored by Ethyca: a developer tools company building the trust infrastructure of the internet. If you have questions or need assistance getting started, let us know at fides@ethyca.com!
