variable "name" {
  type = string
}

variable "default_capacity_provider_strategy" {
  type = any
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