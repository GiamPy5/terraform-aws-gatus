locals {
  decoded_user_gatus_config = yamldecode(var.gatus.config)

  alb_target_group              = var.create_alb ? module.alb-integration[0].target_group_arn : var.alb.target_group_arn
  ecs_ingress_security_group_id = var.create_alb ? module.alb-integration[0].security_group_id : var.ecs.ingress_security_group_id
  alb_target_group_arn          = var.create_alb ? module.alb-integration[0].target_group_arn : var.alb.target_group_arn
  ecs_cluster_arn               = var.create_ecs_cluster ? module.ecs-cluster[0].arn : var.ecs.cluster_arn

  postgres_password_resolved = var.storage_secret_arn != "" ? "__FETCH_FROM_SECRET__.storage.password" : var.postgres_password
  postgres_username_resolved = var.storage_secret_arn != "" ? "__FETCH_FROM_SECRET__.storage.username" : var.postgres_username

  storage_config = {
    postgres = {
      path = "postgres://${local.postgres_username_resolved}:${local.postgres_password_resolved}@${var.postgres_address}:${var.postgres_port}/${var.postgres_db_name}?sslmode=disable"
      type = "postgres"
    }
    sqlite = {
      path = try(var.sqlite_path, "/data/gatus.db")
      type = "sqlite"
    }
    memory = {
      type = "memory"
    }
  }

  security_configs = {
    basic_security_config = {
      basic = {
        username               = try(var.security_config.basic.username, "")
        password-bcrypt-base64 = try(var.security_config.basic.password_bcrypt_base64, "")
      }
    }

    oidc_security_config = {
      oidc = {
        issuer-url       = var.oidc_secret_arn == "" ? try(var.security_config.oidc.issuer_url, "") : "__FETCH_FROM_SECRET__.oidc.issuer-url"
        redirect-url     = var.oidc_secret_arn == "" ? try(var.security_config.oidc.redirect_url, "") : "__FETCH_FROM_SECRET__.oidc.redirect-url"
        client-id        = var.oidc_secret_arn == "" ? try(var.security_config.oidc.client_id, "") : "__FETCH_FROM_SECRET__.oidc.client-id"
        client-secret    = var.oidc_secret_arn == "" ? try(var.security_config.oidc.client_secret, "") : "__FETCH_FROM_SECRET__.oidc.client-secret"
        scopes           = try(var.security_config.oidc.scopes, ["openid"])
        allowed-subjects = try(var.security_config.oidc.allowed_subjects, [])
        session-ttl      = try(var.security_config.oidc.session_ttl, "8h")
      }
    }
  }

  gatus_config = merge(
    local.decoded_user_gatus_config,
    {
      storage = lookup(local.storage_config, var.storage_type, local.storage_config.memory)
    },
    var.security_type != "" ? {
      security = lookup(local.security_configs, "${var.security_type}_security_config", {})
    } : {}
  )

  aws_region = var.aws_region != "" ? var.aws_region : data.aws_region.current.region
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "alb-integration" {
  count = var.create_alb ? 1 : 0

  source = "./modules/alb-integration"

  name                = "${var.name}-alb"
  public_subnets      = var.alb.public_subnets
  vpc_id              = var.alb.vpc_id
  vpc_cidr_block      = var.alb.vpc_cidr_block
  acm_certificate_arn = var.alb.acm_certificate_arn
}

module "ecs-cluster" {
  count = var.create_ecs_cluster ? 1 : 0

  source = "./modules/ecs-cluster"

  name = "${var.name}-ecs-cluster"
}

module "ecs-service" {
  count = var.create_ecs_service ? 1 : 0

  source = "./modules/ecs-service"

  account_id = data.aws_caller_identity.current.account_id
  aws_region = local.aws_region

  name                      = "${var.name}-ecs-service"
  cpu                       = var.ecs.cpu
  memory                    = var.ecs.memory
  subnet_ids                = var.ecs.subnet_ids
  cluster_arn               = local.ecs_cluster_arn
  ingress_security_group_id = local.ecs_ingress_security_group_id

  alb_target_group_arn = local.alb_target_group_arn

  gatus_config                   = yamlencode(local.gatus_config)
  gatus_config_ssm_parameter_arn = var.gatus.config_ssm_parameter_arn
  gatus_deployment_trigger_value = var.gatus.config_ssm_parameter_arn == "" ? md5(yamlencode(local.gatus_config)) : var.gatus.config_ssm_parameter_arn

  storage_secret_arn = var.storage_secret_arn
  oidc_secret_arn    = var.oidc_secret_arn
}