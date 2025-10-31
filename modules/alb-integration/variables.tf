variable "vpc_id" {
  type = string
}

variable "name" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_cidr_block" {
  type = string
}

variable "target_group_port" {
  type    = number
  default = 8080
}

variable "acm_certificate_arn" {
  type = string
  default = ""
}