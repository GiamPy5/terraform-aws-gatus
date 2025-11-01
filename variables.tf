variable "create_alb" {
  type    = bool
  default = true
}

variable "create_ecs_service" {
  type    = bool
  default = true
}

variable "create_ecs_cluster" {
  type    = bool
  default = true
}

variable "name" {
  type    = string
  default = "terraform-aws-gatus-ecs"
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "storage_type" {
  type    = string
  default = "memory"
  validation {
    condition     = contains(["memory", "sqlite", "postgres"], var.storage_type)
    error_message = "storage_type must be either sqlite, postgres or memory"
  }
}

variable "additional_config" {
  type    = string
  default = ""
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "postgres_db_name" {
  type    = string
  default = ""
}

variable "postgres_address" {
  type    = string
  default = ""
}

variable "postgres_username" {
  type    = string
  default = ""
}

variable "postgres_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "postgres_secret_arn" {
  type    = string
  default = ""
}

variable "sqlite_path" {
  type    = string
  default = "/data/gatus.db"
}

variable "security_type" {
  type = string
  default = ""
  validation {
    condition     = var.security_type == "" || contains(["basic", "oidc"], var.security_type)
    error_message = "security_type must be either empty, basic or oidc"
  }
}

variable "security_config" {
  type = object({
    basic = optional(object({
      username = string
      password_bcrypt_base64 = string
    }))
    oidc = optional(object({
      issuer_url = string
      redirect_url = string
      client_id = string
      client_secret = string
      scopes = optional(list(string), ["openid"])
      allowed_subjects = optional(list(string), [])
      session_ttl = optional(string, "8h")
    }))
  })
  default = {}
}

variable "alb" {
  type = object({
    public_subnets      = list(string)
    backend_port        = optional(number, 8080)
    acm_certificate_arn = optional(string, "")
    vpc_cidr_block      = string
    vpc_id              = string
  })
}

variable "ecs" {
  type = object({
    cluster_arn               = optional(string, "")
    cpu                       = optional(number, 2048)
    memory                    = optional(number, 4096)
    subnet_ids                = list(string)
    ingress_security_group_id = optional(string, "")
  })
}

variable "gatus" {
  type = object({
    version                  = optional(string, "v5.29.0")
    config_ssm_parameter_arn = optional(string, "")
    deployment_trigger_value = optional(string, "")
    config                   = string
  })
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "oidc_secret_arn" {
  type    = string
  default = ""
}

variable "storage_secret_arn" {
  type    = string
  default = ""
}