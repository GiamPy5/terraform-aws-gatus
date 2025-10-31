output "load_balancer_dns_name" {
  value = try(module.alb-integration[0].dns_name, "")
}