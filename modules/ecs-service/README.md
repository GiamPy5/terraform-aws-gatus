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
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID used to construct CloudWatch Logs ARNs. | `string` | n/a | yes |
| <a name="input_alb_target_group_arn"></a> [alb\_target\_group\_arn](#input\_alb\_target\_group\_arn) | ARN of the ALB target group the service should register with. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region used for service resources such as CloudWatch log groups. | `string` | n/a | yes |
| <a name="input_cluster_arn"></a> [cluster\_arn](#input\_cluster\_arn) | ARN of the ECS cluster where the service runs. | `string` | n/a | yes |
| <a name="input_container_port"></a> [container\_port](#input\_container\_port) | Port exposed by the Gatus container and registered with the load balancer. | `number` | `8080` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | Total CPU units reserved for the ECS task definition. | `number` | n/a | yes |
| <a name="input_enable_execute_command"></a> [enable\_execute\_command](#input\_enable\_execute\_command) | Whether to enable ECS Exec for the service. | `bool` | `false` | no |
| <a name="input_gatus_config"></a> [gatus\_config](#input\_gatus\_config) | Rendered Gatus configuration content stored in SSM when an external parameter is not supplied. | `string` | `""` | no |
| <a name="input_gatus_config_path"></a> [gatus\_config\_path](#input\_gatus\_config\_path) | Filesystem path inside the container where the Gatus configuration is mounted. | `string` | `"/config"` | no |
| <a name="input_gatus_config_ssm_parameter_arn"></a> [gatus\_config\_ssm\_parameter\_arn](#input\_gatus\_config\_ssm\_parameter\_arn) | ARN of an existing SSM parameter containing the Gatus configuration to reuse. | `string` | `""` | no |
| <a name="input_gatus_deployment_trigger_value"></a> [gatus\_deployment\_trigger\_value](#input\_gatus\_deployment\_trigger\_value) | This value is passed as environment variable to the task definition. This helps to force a new ECS task deployment when the configuration changes as it acts as a trigger. | `string` | `""` | no |
| <a name="input_gatus_version"></a> [gatus\_version](#input\_gatus\_version) | Container image tag to use for the Gatus task. | `string` | `"v5.29.0"` | no |
| <a name="input_host_port"></a> [host\_port](#input\_host\_port) | Host port to map to the container port within the ECS task definition. | `number` | `8080` | no |
| <a name="input_ingress_security_group_id"></a> [ingress\_security\_group\_id](#input\_ingress\_security\_group\_id) | ID of the security group allowed to reach the service (typically the ALB security group). | `string` | n/a | yes |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used to encrypt the managed SSM parameter. | `string` | `""` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount of memory (in MiB) reserved for the ECS task definition. | `number` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name assigned to the ECS service and related resources. | `string` | n/a | yes |
| <a name="input_oidc_secret_arn"></a> [oidc\_secret\_arn](#input\_oidc\_secret\_arn) | ARN of the Secrets Manager secret containing OIDC configuration for Gatus. | `string` | `""` | no |
| <a name="input_storage_secret_arn"></a> [storage\_secret\_arn](#input\_storage\_secret\_arn) | ARN of the Secrets Manager secret providing storage credentials for Gatus. | `string` | `""` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets where the ECS service tasks are deployed. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to resources created by this module. | `map(any)` | `{}` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

---

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/GiamPy5/terraform-aws-gatus-ecs/blob/main/LICENSE).