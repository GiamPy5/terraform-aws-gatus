variable "container_port" {
  type    = number
  default = 8080
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "host_port" {
  type    = number
  default = 8080
}

variable "subnet_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "gatus_version" {
  type    = string
  default = "v5.29.0"
}

variable "gatus_deployment_trigger_value" {
  type        = string
  default     = ""
  description = "This value is passed as environment variable to the task definition. This helps to force a new ECS task deployment when the configuration changes as it acts as a trigger."
}

variable "kms_key_arn" {
  type    = string
  default = ""
}

variable "gatus_config_path" {
  type    = string
  default = "/config"
}

variable "alb_target_group_arn" {
  type = string
}

variable "ingress_security_group_id" {
  type = string
}

variable "name" {
  type = string
}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "cluster_arn" {
  type = string
}

variable "enable_execute_command" {
  type    = bool
  default = false
}

variable "storage_secret_arn" {
  type    = string
  default = ""
}

variable "oidc_secret_arn" {
  type    = string
  default = ""
}

variable "gatus_config" {
  type    = string
  default = ""
}

variable "gatus_config_ssm_parameter_arn" {
  type    = string
  default = ""
}
