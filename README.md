# terraform-aws-gatus-ecs

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.4-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/github/license/GiamPy5/terraform-aws-gatus-ecs)](LICENSE)

Terraform module that deploys [Gatus](https://github.com/TwiN/gatus) on AWS Fargate with optional Application Load Balancer integration, freshly provisioned ECS infrastructure, and secret-aware configuration delivery via AWS Systems Manager Parameter Store and Secrets Manager.

## Table of Contents

- [Highlights](#highlights)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Guide](#configuration-guide)
- [Inputs (highlights)](#inputs-highlights)
- [Outputs](#outputs)
- [Operations](#operations)
- [Security & IAM](#security--iam)
- [Development](#development)
- [Support & Contributions](#support--contributions)

## Highlights

- ✅ Zero-to-running Gatus on Fargate with one module invocation.
- 🧩 Pluggable submodules: toggle ALB, ECS cluster, or service creation independently.
- 🔐 Secrets-aware config loader resolves `__FETCH_FROM_SECRET__.*` markers at runtime.
- 📦 Storage backends for memory, SQLite, or Postgres with minimal toggles.
- 🛰️ Built-in Service Connect namespace for service discovery inside your VPC.

## Architecture

```
        +---------------------------+
        |  AWS Application Load     |
        |  Balancer (optional)      |
        +-------------+-------------+
                      |
             target_group_arn
                      |
        +-------------v-------------+
        |  AWS ECS Service (Fargate)|  <- gatus container
        |  - gatus-config-loader    |  <- sidecar container
        +-------------+-------------+
                      |
       +--------------+--------------+
       |  AWS ECS Cluster (optional) |
       +--------------+--------------+
                      |
        +-------------v-------------+
        |  AWS SSM Parameter Store  |
        |  AWS Secrets Manager      |
        +---------------------------+
```

The loader sidecar fetches the latest Gatus configuration (from SSM or a provided ARN), replaces any secret placeholders with data from Secrets Manager, writes the final YAML into `/config/user_config.yaml`, then signals the main container to boot.

## Prerequisites

- Terraform `>= 1.4.0`
- AWS provider `~> 6.0`
- AWS credentials with permissions to create/manage ALB, ECS, IAM, CloudWatch Logs, SSM Parameter Store, Secrets Manager, Service Discovery, and optional KMS keys.

## Quick Start

Copy the example below into your Terraform project. Adjust networking, KMS, and database modules to fit your environment.

```hcl
terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

module "gatus" {
  source = "github.com/GiamPy5/terraform-aws-gatus-ecs"

  name = "prod-gatus"

  create_alb         = true
  create_ecs_cluster = true
  create_ecs_service = true

  alb = {
    public_subnets      = module.vpc.public_subnets
    vpc_id              = module.vpc.vpc_id
    vpc_cidr_block      = module.vpc.vpc_cidr_block
    acm_certificate_arn = aws_acm_certificate.gatus.arn
  }

  ecs = {
    subnet_ids = module.vpc.private_subnets
  }

  kms_key_arn = aws_kms_key.gatus.arn

  gatus = {
    config = file("${path.module}/config.yaml")
  }

  storage_type        = "postgres"
  postgres_address    = module.rds.address
  postgres_db_name    = "gatus"
  storage_secret_arn  = module.rds.master_user_secret_arn

  tags = {
    Project = "monitoring"
  }
}
```

See `examples/complete` for a full environment that provisions networking, RDS, KMS, and VPC endpoints alongside the module.

## Configuration Guide

- **Gatus configuration**  
  Supply the raw YAML via `var.gatus.config`. Unless you pass `gatus.config_ssm_parameter_arn`, the module writes the content to SSM Parameter Store and mounts it inside the container at `/config/user_config.yaml`.

- **Secrets placeholders**  
  Use placeholders like `__FETCH_FROM_SECRET__.storage.password` or `__FETCH_FROM_SECRET__.oidc.client-secret` in the Gatus config. Provide `storage_secret_arn` and/or `oidc_secret_arn`; the loader sidecar will fetch the referenced secret and substitute the value at runtime.
  - The ECS task definition injects the secret value into the loader container via native ECS Secrets (`STORAGE_SECRET`, `OIDC_SECRET`). If the payload is JSON (e.g., RDS generated credentials), the loader parses it and resolves placeholders without another Secrets Manager API call. When the environment variable still contains an ARN (for backward compatibility), the loader falls back to fetching it directly.

- **Storage selection**  
  Pick the backend with `var.storage_type`. Postgres usage requires address, database name, port, and credentials. Supply credentials either as standard variables or, preferably, via Secrets Manager.

- **Security configuration**  
  Enable `basic` or `oidc` auth by setting `var.security_type` and adding the respective object in `var.security_config`. OIDC credentials can also be delivered through Secrets Manager placeholders.

- **Postgres credentials**  
  When `storage_type = "postgres"` and `storage_secret_arn` is set, the module automatically injects placeholders for `__FETCH_FROM_SECRET__.storage.username` and `.password`, so the loader resolves them from the provided secret.
  - Retrieved usernames/passwords are URL-encoded by the loader to keep the resulting DSN valid even when credentials contain special characters.

- **Existing infrastructure**  
  When integrating with pre-existing ALB or ECS resources, set `create_alb`, `create_ecs_cluster`, or `create_ecs_service` to `false` and pass the required ARNs (e.g., `var.alb.target_group_arn`, `var.ecs.cluster_arn`).

> ⚠️ **Sensitive data**  
> Prefer submitting credentials through Secrets Manager ARNs (`storage_secret_arn`, `oidc_secret_arn`) instead of plaintext Terraform variables. This keeps secrets out of state files, version control, and CLI history.

---

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb-integration"></a> [alb-integration](#module\_alb-integration) | ./modules/alb-integration | n/a |
| <a name="module_ecs-cluster"></a> [ecs-cluster](#module\_ecs-cluster) | ./modules/ecs-cluster | n/a |
| <a name="module_ecs-service"></a> [ecs-service](#module\_ecs-service) | ./modules/ecs-service | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_config"></a> [additional\_config](#input\_additional\_config) | n/a | `string` | `""` | no |
| <a name="input_alb"></a> [alb](#input\_alb) | n/a | <pre>object({<br/>    public_subnets      = list(string)<br/>    backend_port        = optional(number, 8080)<br/>    acm_certificate_arn = optional(string, "")<br/>    vpc_cidr_block      = string<br/>    vpc_id              = string<br/>  })</pre> | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | `""` | no |
| <a name="input_create_alb"></a> [create\_alb](#input\_create\_alb) | n/a | `bool` | `true` | no |
| <a name="input_create_ecs_cluster"></a> [create\_ecs\_cluster](#input\_create\_ecs\_cluster) | n/a | `bool` | `true` | no |
| <a name="input_create_ecs_service"></a> [create\_ecs\_service](#input\_create\_ecs\_service) | n/a | `bool` | `true` | no |
| <a name="input_ecs"></a> [ecs](#input\_ecs) | n/a | <pre>object({<br/>    cluster_arn               = optional(string, "")<br/>    cpu                       = optional(number, 2048)<br/>    memory                    = optional(number, 4096)<br/>    subnet_ids                = list(string)<br/>    ingress_security_group_id = optional(string, "")<br/>  })</pre> | n/a | yes |
| <a name="input_gatus"></a> [gatus](#input\_gatus) | n/a | <pre>object({<br/>    version                  = optional(string, "v5.29.0")<br/>    config_ssm_parameter_arn = optional(string, "")<br/>    deployment_trigger_value = optional(string, "")<br/>    config                   = string<br/>  })</pre> | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | n/a | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | `"terraform-aws-gatus-ecs"` | no |
| <a name="input_oidc_secret_arn"></a> [oidc\_secret\_arn](#input\_oidc\_secret\_arn) | n/a | `string` | `""` | no |
| <a name="input_postgres_address"></a> [postgres\_address](#input\_postgres\_address) | n/a | `string` | `""` | no |
| <a name="input_postgres_db_name"></a> [postgres\_db\_name](#input\_postgres\_db\_name) | n/a | `string` | `""` | no |
| <a name="input_postgres_password"></a> [postgres\_password](#input\_postgres\_password) | n/a | `string` | `""` | no |
| <a name="input_postgres_port"></a> [postgres\_port](#input\_postgres\_port) | n/a | `number` | `5432` | no |
| <a name="input_postgres_secret_arn"></a> [postgres\_secret\_arn](#input\_postgres\_secret\_arn) | n/a | `string` | `""` | no |
| <a name="input_postgres_username"></a> [postgres\_username](#input\_postgres\_username) | n/a | `string` | `""` | no |
| <a name="input_security_config"></a> [security\_config](#input\_security\_config) | n/a | <pre>object({<br/>    basic = optional(object({<br/>      username = string<br/>      password_bcrypt_base64 = string<br/>    }))<br/>    oidc = optional(object({<br/>      issuer_url = string<br/>      redirect_url = string<br/>      client_id = string<br/>      client_secret = string<br/>      scopes = optional(list(string), ["openid"])<br/>      allowed_subjects = optional(list(string), [])<br/>      session_ttl = optional(string, "8h")<br/>    }))<br/>  })</pre> | `{}` | no |
| <a name="input_security_type"></a> [security\_type](#input\_security\_type) | n/a | `string` | `""` | no |
| <a name="input_sqlite_path"></a> [sqlite\_path](#input\_sqlite\_path) | n/a | `string` | `"/data/gatus.db"` | no |
| <a name="input_storage_secret_arn"></a> [storage\_secret\_arn](#input\_storage\_secret\_arn) | n/a | `string` | `""` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | n/a | `string` | `"memory"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_load_balancer_dns_name"></a> [load\_balancer\_dns\_name](#output\_load\_balancer\_dns\_name) | n/a |
<!-- END_TF_DOCS -->

---

## Operations

1. Initialise providers: `terraform init`
2. Review configuration: `terraform plan`
3. Apply changes: `terraform apply`
4. Validate drift: rerun `terraform plan` and review CloudWatch Logs (`/aws/ecs/containerinsights/<name>`) for loader messages.

## Security & IAM

Ensure the task execution role can:

- Decrypt the configured SSM parameter and any Secrets Manager ARNs you reference.
- Read logs in CloudWatch Logs (`logs:*` as configured in `modules/ecs-service/main.tf`).

The module grants least-privilege statements tailored to the provided inputs, but you remain responsible for KMS key policies and secret creation.

## Development

- Run `terraform fmt` and `terraform validate` before submitting changes.
- Use the `examples/complete` stack to test real deployments.
- Lint Python changes in `modules/ecs-service/config_loader.py` (PEP8) and keep dependencies to standard library only.

## Support & Contributions

Issues and contributions are welcome. Please open a ticket or submit a pull request describing your scenario and any validation steps performed (`terraform validate`, etc.).
