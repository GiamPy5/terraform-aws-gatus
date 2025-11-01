variable "name" {
  description = "Name assigned to the ECS cluster."
  type        = string
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy map applied to the ECS cluster."
  type        = any
  default = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
}
