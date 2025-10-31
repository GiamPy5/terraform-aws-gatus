locals {
  container_name = "gatus"
  container_port = var.container_port
  host_port      = var.host_port

  gatus_config_ssm_param_arn = var.gatus_config_ssm_parameter_arn == "" ? aws_ssm_parameter.gatus_config[0].arn : var.gatus_config_ssm_parameter_arn
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 6.7"

  cluster_arn = var.cluster_arn

  name = var.name

  cpu    = var.cpu
  memory = var.memory

  enable_execute_command = var.enable_execute_command

  task_exec_iam_statements = concat(
    var.kms_key_arn != "" ? [{
      actions   = ["kms:Decrypt"]
      effect    = "Allow"
      resources = [var.kms_key_arn]
    }] : [],
    [{
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams"
      ]
      effect = "Allow"
      resources = [
        "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/ecs/containerinsights/${var.name}:*"
      ]
    }]
  )

  task_exec_secret_arns = flatten(concat(
    var.storage_secret_arn == "" ? [] : [var.storage_secret_arn],
    var.oidc_secret_arn == "" ? [] : [var.oidc_secret_arn]
  ))

  tasks_iam_role_statements = concat(
    var.kms_key_arn != "" ? [{
      actions   = ["kms:Decrypt"]
      effect    = "Allow"
      resources = [var.kms_key_arn]
    }] : [],
    [
      {
        actions = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams"
        ]
        effect = "Allow"
        resources = [
          "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:/aws/ecs/containerinsights/${var.name}:*"
        ]
      },
      {
        actions   = ["ssm:GetParameter"]
        effect    = "Allow"
        resources = [local.gatus_config_ssm_param_arn]
      }
    ]
  )

  create_task_exec_policy = true

  depends_on = [
    aws_cloudwatch_log_group.gatus
  ]

  volume = {
    config = {}
  }

  container_definitions = {
    gatus-config-loader = {
      cpu               = 128
      memory            = 256
      memoryReservation = 256
      essential         = false
      environment = [
        {
          name  = "GATUS_CONFIG_SSM_PARAM"
          value = local.gatus_config_ssm_param_arn
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "MANAGED_GATUS_CONFIG"
          value = var.gatus_config_ssm_parameter_arn != "" ? true : false
        },
        {
          name  = "DEPLOYMENT_TRIGGER"
          value = var.gatus_deployment_trigger_value
        }
      ]
      secrets = coalesce(flatten(concat(
        var.storage_secret_arn != "" ? [
          {
            name      = "STORAGE_SECRET_ARN"
            valueFrom = var.storage_secret_arn
          }
        ] : [],
        var.oidc_secret_arn != "" ? [
          {
            name      = "OIDC_SECRET_ARN"
            valueFrom = var.oidc_secret_arn
          }
        ] : [],
      )), [])
      image      = "public.ecr.aws/aws-cli/aws-cli:2.31.24"
      entrypoint = ["python3", "-c"]
      command = [<<-PY
        ${file("${path.module}/config_loader.py")}
      PY
      ]

      mountPoints = [{ sourceVolume = "config", containerPath = "/config", readOnly = false }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/containerinsights/${var.name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.name}-loader"
        }
      }
    }
    gatus = {
      cpu               = var.cpu - 128
      memory            = var.memory - 256
      memoryReservation = var.memory - 256
      essential         = true
      image             = "twinproduction/gatus:${var.gatus_version}"
      portMappings = [
        {
          name          = "gatus"
          containerPort = local.container_port
          hostPort      = local.host_port
          protocol      = "tcp"
        }
      ]
      enable_cloudwatch_logging = false

      dependsOn = [
        {
          containerName = "gatus-config-loader"
          condition     = "SUCCESS"
        }
      ]

      mountPoints = [{ sourceVolume = "config", containerPath = "/config", readOnly = true }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/aws/ecs/containerinsights/${var.name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.name}-gatus"
        }
      }
      environment = [
        {
          name  = "GATUS_CONFIG_PATH"
          value = var.gatus_config_path
        },
        {
          name  = "GATUS_DEPLOYMENT_TRIGGER",
          value = var.gatus_deployment_trigger_value
        }
      ]
    }
  }

  load_balancer = {
    service = {
      target_group_arn = var.alb_target_group_arn
      container_name   = local.container_name
      container_port   = local.container_port
    }
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.this.arn
    service = [{
      client_alias = {
        port     = local.container_port
        dns_name = local.container_name
      }
      port_name      = local.container_name
      discovery_name = local.container_name
    }]
  }

  security_group_ingress_rules = {
    alb_ingress_8080 = {
      type                         = "ingress"
      from_port                    = var.container_port
      to_port                      = var.host_port
      protocol                     = "tcp"
      description                  = "Gatus Service Port"
      referenced_security_group_id = var.ingress_security_group_id
    }
  }

  security_group_egress_rules = {
    egress_all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  service_tags = var.tags
  tags         = var.tags

  subnet_ids = var.subnet_ids
}

resource "aws_cloudwatch_log_group" "gatus" {
  name = "/aws/ecs/containerinsights/${var.name}"
  tags = var.tags
}

resource "aws_service_discovery_http_namespace" "this" {
  name = var.name
  tags = var.tags
}

resource "aws_ssm_parameter" "gatus_config" {
  count  = var.gatus_config_ssm_parameter_arn == "" ? 1 : 0
  name   = "/${var.name}/gatus-config"
  type   = "SecureString"
  key_id = var.kms_key_arn
  value  = var.gatus_config
}