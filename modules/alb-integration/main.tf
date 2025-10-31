locals {
  secure = var.acm_certificate_arn != ""

  security_group_ingress_rule_definitions = [
    {
      key     = "all_http"
      enabled = true
      value = {
        from_port   = 80
        to_port     = 80
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
    },
    {
      key     = "all_https"
      enabled = local.secure
      value = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
  ]

  security_group_ingress_rules = {
    for rule in local.security_group_ingress_rule_definitions : rule.key => rule.value if rule.enabled
  }

  listener_definitions = [
    {
      key     = "ex-http"
      enabled = !local.secure
      value = {
        port     = 80
        protocol = "HTTP"
        forward = {
          target_group_key = "ecs"
        }
      }
    },
    {
      key     = "ex-http-https-redirect"
      enabled = local.secure
      value = {
        port     = 80
        protocol = "HTTP"
        redirect = {
          port        = 443
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    },
    {
      key     = "ex-https"
      enabled = local.secure
      value = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
        certificate_arn = var.acm_certificate_arn
        forward = {
          target_group_key = "ecs"
        }
      }
    }
  ]

  listeners = {
    for listener in local.listener_definitions : listener.key => listener.value if listener.enabled
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name = var.name

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = local.security_group_ingress_rules

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
    }
  }

  listeners = local.listeners

  target_groups = {
    ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = var.target_group_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      create_attachment                 = false

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
    }
  }
}
