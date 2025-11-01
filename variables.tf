variable "create_alb" {
  description = "Controls whether this module provisions the accompanying Application Load Balancer integration."
  type        = bool
  default     = true
}

variable "create_ecs_service" {
  description = "Controls whether the ECS service resources are created."
  type        = bool
  default     = true
}

variable "create_ecs_cluster" {
  description = "Controls whether a new ECS cluster is created instead of using an existing one."
  type        = bool
  default     = true
}

variable "name" {
  description = "Base name used when generating resource names."
  type        = string
  default     = "terraform-aws-gatus-ecs"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the generated Gatus configuration parameter."
  type        = string
  default     = ""
}

variable "storage_type" {
  description = "Type of storage backend to configure in the Gatus deployment."
  type        = string
  default     = "memory"
  validation {
    condition     = contains(["memory", "sqlite", "postgres"], var.storage_type)
    error_message = "storage_type must be either sqlite, postgres or memory"
  }
}

variable "additional_config" {
  description = "Additional YAML configuration to merge into the rendered Gatus configuration."
  type        = string
  default     = ""
}

variable "postgres_port" {
  description = "Port number used when building the Postgres connection string."
  type        = number
  default     = 5432
}

variable "postgres_db_name" {
  description = "Database name included in the Postgres connection string."
  type        = string
  default     = ""
}

variable "postgres_address" {
  description = "Hostname or endpoint used to reach the Postgres instance."
  type        = string
  default     = ""
}

variable "postgres_username" {
  description = "Username included in the Postgres connection string."
  type        = string
  default     = ""
}

variable "postgres_password" {
  description = "Password included in the Postgres connection string."
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgres_secret_arn" {
  description = "ARN of a Secrets Manager secret that stores Postgres credentials."
  type        = string
  default     = ""
}

variable "sqlite_path" {
  description = "Path inside the container for the SQLite database file."
  type        = string
  default     = "/data/gatus.db"
}

variable "security_type" {
  description = "Authentication mode for the Gatus instance: basic, oidc, or left empty for none."
  type        = string
  default     = ""
  validation {
    condition     = var.security_type == "" || contains(["basic", "oidc"], var.security_type)
    error_message = "security_type must be either empty, basic or oidc"
  }
}

variable "security_config" {
  description = "Security configuration values that accompany the selected security_type."
  type = object({
    basic = optional(object({
      username               = string
      password_bcrypt_base64 = string
    }))
    oidc = optional(object({
      issuer_url       = string
      redirect_url     = string
      client_id        = string
      client_secret    = string
      scopes           = optional(list(string), ["openid"])
      allowed_subjects = optional(list(string), [])
      session_ttl      = optional(string, "8h")
    }))
  })
  default = {}
}

variable "alb" {
  description = "Configuration for an existing ALB integration when create_alb is false."
  type = object({
    public_subnets      = list(string)
    backend_port        = optional(number, 8080)
    acm_certificate_arn = optional(string, "")
    vpc_cidr_block      = string
    vpc_id              = string
  })
}

variable "ecs" {
  description = "Inputs for the ECS service, including network configuration and optional cluster ARN."
  type = object({
    cluster_arn               = optional(string, "")
    cpu                       = optional(number, 2048)
    memory                    = optional(number, 4096)
    subnet_ids                = list(string)
    ingress_security_group_id = optional(string, "")
  })
}

variable "gatus" {
  description = "Configuration for the Gatus service, including version and configuration source."
  type = object({
    version                  = optional(string, "v5.29.0")
    config_ssm_parameter_arn = optional(string, "")
    deployment_trigger_value = optional(string, "")
    config                   = string
  })
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(any)
  default     = {}
}

variable "aws_region" {
  description = "AWS region override used for providers and logging; defaults to the current region when empty."
  type        = string
  default     = ""
}

variable "oidc_secret_arn" {
  description = "ARN of the Secrets Manager secret that stores OIDC authentication values."
  type        = string
  default     = ""
}

variable "storage_secret_arn" {
  description = "ARN of the Secrets Manager secret containing storage credentials for Postgres or other backends."
  type        = string
  default     = ""
}
