# terraform-aws-gatus

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.4-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/github/license/GiamPy5/terraform-aws-gatus)](LICENSE)

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
  source = "github.com/GiamPy5/terraform-aws-gatus"

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

## Inputs (highlights)

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | `string` | `"terraform-aws-gatus"` | Base name applied to created resources. |
| `create_alb` / `create_ecs_cluster` / `create_ecs_service` | `bool` | `true` | Control which submodules are created. |
| `alb` | `object` | n/a | Required networking inputs when creating an ALB (public subnets, VPC, etc.). |
| `ecs` | `object` | n/a | ECS service inputs (subnets, task sizing, optional existing cluster/security group). |
| `gatus` | `object` | n/a | Gatus runtime settings (version, config payload, optional SSM parameter ARN). |
| `storage_type` | `string` | `"memory"` | Backend selection (`memory`, `sqlite`, `postgres`). |
| `security_type` | `string` | `""` | Enable `basic` or `oidc` auth using `security_config`. |
| `storage_secret_arn` / `oidc_secret_arn` | `string` | `""` | Secrets Manager ARNs used by the loader to fill placeholders. |
| `kms_key_arn` | `string` | `""` | Optional KMS key for SSM parameter and task permissions. |

Refer to `variables.tf` for the full list with default values and validation rules.

## Outputs

- `load_balancer_dns_name` – ALB DNS name when the module creates the load balancer.
- Sub-module specific outputs (e.g., target group ARN, security group ID) are exposed through the nested modules.

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
