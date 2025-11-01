provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  vpc_cidr_block = "42.0.0.0/16"
  region         = "eu-central-1"
  name           = "ex-${basename(path.cwd)}"

  db_name = "gatus"

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/GiamPy5/terraform-aws-gatus-ecs"
  }
}

################################################################################
# Gatus
################################################################################
module "gatus" {
  source = "./../../"

  create_alb         = true
  create_ecs_cluster = true
  create_ecs_service = true

  alb = {
    public_subnets = module.vpc.public_subnets
    vpc_id         = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
  }

  ecs = {
    subnet_ids = module.vpc.private_subnets
  }

  kms_key_arn = module.kms.key_arn

  gatus = {
    config = file("${path.root}/config.yaml")
  }

  postgres_address = module.rds.db_instance_address
  postgres_db_name = local.db_name
  storage_secret_arn = module.rds.db_instance_master_user_secret_arn

  storage_type = "postgres"
}

################################################################################
# Supporting Resources
################################################################################
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 4.1"

  deletion_window_in_days = 7
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.13"

  db_name        = local.db_name
  engine         = "postgres"
  engine_version = "14"
  family         = "postgres14"
  identifier     = "${local.name}-rds"
  instance_class = "db.t4g.micro"

  allocated_storage = 5
  username = replace("${local.name}admin", "-", "")

  kms_key_id = module.kms.key_arn

  manage_master_user_password = true

  vpc_security_group_ids = [
    module.rds_security_group.security_group_id
  ]

  db_subnet_group_name = module.vpc.database_subnet_group
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = local.vpc_cidr_block

  azs              = local.azs
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_block, 8, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_block, 8, k + 4)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr_block, 8, k + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true

  create_database_subnet_group = true

  manage_default_security_group = true

  default_security_group_ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.vpc_cidr_block
  }]

  default_security_group_egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = local.tags
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 6.0"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_name_prefix = "${local.name}-endpoints-"

  security_group_rules = {
    ingress_https = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    ssm         = { service = "ssm", private_dns_enabled = true, subnet_ids = module.vpc.private_subnets }
    ssmmessages = { service = "ssmmessages", private_dns_enabled = true, subnet_ids = module.vpc.private_subnets }
    ec2messages = { service = "ec2messages", private_dns_enabled = true, subnet_ids = module.vpc.private_subnets }
  }
}
module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-rds-sg"
  description = "Security group for example RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [{
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
    cidr_blocks = module.vpc.vpc_cidr_block
  }]

  egress_with_cidr_blocks = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
  }]

  tags = local.tags
}
