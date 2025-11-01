# Gatus ECS - ECS Service Module

---

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs_service"></a> [ecs\_service](#module\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | ~> 6.7 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.gatus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_service_discovery_http_namespace.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_http_namespace) | resource |
| [aws_ssm_parameter.gatus_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_alb_target_group_arn"></a> [alb\_target\_group\_arn](#input\_alb\_target\_group\_arn) | n/a | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | n/a | yes |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | n/a | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | n/a | `number` | `8080` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | n/a | `number` | n/a | yes |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | n/a | `bool` | `false` | no |
| <a name="input_gatus_config"></a> [gatus\_config](#input\_gatus\_config) | n/a | `string` | `""` | no |
| <a name="input_gatus_config_path"></a> [gatus\_config\_path](#input\_gatus\_config\_path) | n/a | `string` | `"/config"` | no |
| <a name="input_gatus_config_ssm_parameter_arn"></a> [gatus\_config\_ssm\_parameter\_arn](#input\_gatus\_config\_ssm\_parameter\_arn) | n/a | `string` | `""` | no |
| <a name="input_gatus_deployment_trigger_value"></a> [gatus\_deployment\_trigger\_value](#input\_gatus\_deployment\_trigger\_value) | This value is passed as environment variable to the task definition. This helps to force a new ECS task deployment when the configuration changes as it acts as a trigger. | `string` | `""` | no |
| <a name="input_gatus_version"></a> [gatus\_version](#input\_gatus\_version) | n/a | `string` | `"v5.29.0"` | no |
| <a name="input_host_port"></a> [host\_port](#input\_host\_port) | n/a | `number` | `8080` | no |
| <a name="input_ingress_security_group_id"></a> [ingress\_security\_group\_id](#input\_ingress\_security\_group\_id) | n/a | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | n/a | `string` | `""` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | n/a | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_oidc_secret_arn"></a> [oidc\_secret\_arn](#input\_oidc\_secret\_arn) | n/a | `string` | `""` | no |
| <a name="input_storage_secret_arn"></a> [storage\_secret\_arn](#input\_storage\_secret\_arn) | n/a | `string` | `""` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

---