output "target_group_arn" {
  value = module.alb.target_groups["ecs"].arn
}

output "security_group_id" {
  value = module.alb.security_group_id
}

output "dns_name" {
  value = module.alb.dns_name
}