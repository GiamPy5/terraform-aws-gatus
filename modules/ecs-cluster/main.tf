module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 6.7"

  name = var.name

  default_capacity_provider_strategy = var.default_capacity_provider_strategy
}
