variable "vpc_id" {
  description = "ID of the VPC that hosts the Application Load Balancer."
  type        = string
}

variable "name" {
  description = "Base name applied to ALB resources created by this module."
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs where the ALB is deployed."
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block of the VPC used to configure ALB security group egress."
  type        = string
}

variable "target_group_port" {
  description = "Port on which the target group forwards traffic to the ECS service."
  type        = number
  default     = 8080
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for enabling HTTPS listeners; leave blank to disable HTTPS."
  type        = string
  default     = ""
}
