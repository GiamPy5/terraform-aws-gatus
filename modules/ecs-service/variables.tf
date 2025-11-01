variable "container_port" {
  description = "Port exposed by the Gatus container and registered with the load balancer."
  type        = number
  default     = 8080
}

variable "aws_region" {
  description = "AWS region used for service resources such as CloudWatch log groups."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used to construct CloudWatch Logs ARNs."
  type        = string
}

variable "host_port" {
  description = "Host port to map to the container port within the ECS task definition."
  type        = number
  default     = 8080
}

variable "subnet_ids" {
  description = "Subnets where the ECS service tasks are deployed."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to resources created by this module."
  type        = map(any)
  default     = {}
}

variable "gatus_version" {
  description = "Container image tag to use for the Gatus task."
  type        = string
  default     = "v5.29.0"
}

variable "gatus_deployment_trigger_value" {
  description = "This value is passed as environment variable to the task definition. This helps to force a new ECS task deployment when the configuration changes as it acts as a trigger."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the managed SSM parameter."
  type        = string
  default     = ""
}

variable "gatus_config_path" {
  description = "Filesystem path inside the container where the Gatus configuration is mounted."
  type        = string
  default     = "/config"
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group the service should register with."
  type        = string
}

variable "ingress_security_group_id" {
  description = "ID of the security group allowed to reach the service (typically the ALB security group)."
  type        = string
}

variable "name" {
  description = "Name assigned to the ECS service and related resources."
  type        = string
}

variable "cpu" {
  description = "Total CPU units reserved for the ECS task definition."
  type        = number
}

variable "memory" {
  description = "Amount of memory (in MiB) reserved for the ECS task definition."
  type        = number
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster where the service runs."
  type        = string
}

variable "enable_execute_command" {
  description = "Whether to enable ECS Exec for the service."
  type        = bool
  default     = false
}

variable "storage_secret_arn" {
  description = "ARN of the Secrets Manager secret providing storage credentials for Gatus."
  type        = string
  default     = ""
}

variable "oidc_secret_arn" {
  description = "ARN of the Secrets Manager secret containing OIDC configuration for Gatus."
  type        = string
  default     = ""
}

variable "gatus_config" {
  description = "Rendered Gatus configuration content stored in SSM when an external parameter is not supplied."
  type        = string
  default     = ""
}

variable "gatus_config_ssm_parameter_arn" {
  description = "ARN of an existing SSM parameter containing the Gatus configuration to reuse."
  type        = string
  default     = ""
}
