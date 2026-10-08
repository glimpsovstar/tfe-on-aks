# tfe-infra

Wraps HashiCorp's HVD module 0.3.0 (vendored in `vendor/terraform-enterprise-aks-hvd` with the patches in its `PATCHES.md`). Sizing presets, Managed Redis, workload identity, DNS and Helm overrides turned off because tfe-install owns them.

## Sizing presets

| Setting | lab | small | production |
| ------- | --- | ----- | ---------- |
| AKS node VM size | Standard_D4ds_v5 | Standard_D8ds_v5 | Standard_D8ds_v5 |
| AKS node count | 2 | 2 | 3 |
| Dedicated TFE node pool | no | no | yes |
| PostgreSQL SKU | GP_Standard_D2ds_v4 | GP_Standard_D4ds_v4 | GP_Standard_D4ds_v4 |
| PostgreSQL HA | no | no | yes |
| Managed Redis SKU | Balanced_B0 | Balanced_B3 | Balanced_B3 |
| Redis HA | no | yes | yes |
| Storage replication | ZRS | ZRS | ZRS |
| TFE replicas | 1 | 1 | 3 |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.67 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.9 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.9 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_tfe"></a> [tfe](#module\_tfe) | ../../vendor/terraform-enterprise-aks-hvd | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aks_authorized_cidrs"></a> [aks\_authorized\_cidrs](#input\_aks\_authorized\_cidrs) | /32 CIDRs allowed on the AKS API (agent IP + operators). | `list(string)` | n/a | yes |
| <a name="input_aks_kubernetes_version"></a> [aks\_kubernetes\_version](#input\_aks\_kubernetes\_version) | AKS version supported in the region and by TFE (az aks get-versions -l australiaeast). | `string` | n/a | yes |
| <a name="input_aks_subnet_id"></a> [aks\_subnet\_id](#input\_aks\_subnet\_id) | AKS node subnet ID. | `string` | n/a | yes |
| <a name="input_db_password_secret_name"></a> [db\_password\_secret\_name](#input\_db\_password\_secret\_name) | Name of the Key Vault secret with the database password. | `string` | n/a | yes |
| <a name="input_db_subnet_id"></a> [db\_subnet\_id](#input\_db\_subnet\_id) | PostgreSQL delegated subnet ID. | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault ID holding the database password secret. | `string` | n/a | yes |
| <a name="input_lb_subnet_id"></a> [lb\_subnet\_id](#input\_lb\_subnet\_id) | Load balancer subnet ID. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"australiaeast"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Name prefix for resources (3-10 lowercase alphanumerics, no 'tfe'). | `string` | n/a | yes |
| <a name="input_redis_subnet_id"></a> [redis\_subnet\_id](#input\_redis\_subnet\_id) | Redis private endpoint subnet ID. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Existing resource group to deploy into. | `string` | n/a | yes |
| <a name="input_size"></a> [size](#input\_size) | Sizing preset: lab, small or production. | `string` | `"lab"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_tfe_hostname"></a> [tfe\_hostname](#input\_tfe\_hostname) | TFE FQDN. | `string` | n/a | yes |
| <a name="input_tfe_version"></a> [tfe\_version](#input\_tfe\_version) | TFE semver, 1.0.1 or later (selects Azure Managed Redis in the HVD module). | `string` | `"2.0.8"` | no |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | Virtual network ID. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aks_cluster_name"></a> [aks\_cluster\_name](#output\_aks\_cluster\_name) | AKS cluster name. |
| <a name="output_effective_settings"></a> [effective\_settings](#output\_effective\_settings) | Resolved sizing preset (for tests and review). |
| <a name="output_kube_client_certificate"></a> [kube\_client\_certificate](#output\_kube\_client\_certificate) | Base64 client certificate (cluster-admin on a local-account cluster). |
| <a name="output_kube_client_key"></a> [kube\_client\_key](#output\_kube\_client\_key) | Base64 client key (cluster-admin on a local-account cluster). |
| <a name="output_kube_cluster_ca_certificate"></a> [kube\_cluster\_ca\_certificate](#output\_kube\_cluster\_ca\_certificate) | Base64 cluster CA. |
| <a name="output_kube_host"></a> [kube\_host](#output\_kube\_host) | AKS API endpoint. |
| <a name="output_replica_count"></a> [replica\_count](#output\_replica\_count) | TFE pod count for this size. |
| <a name="output_tfe_database_host"></a> [tfe\_database\_host](#output\_tfe\_database\_host) | PostgreSQL host:5432. |
| <a name="output_tfe_database_name"></a> [tfe\_database\_name](#output\_tfe\_database\_name) | Database name. |
| <a name="output_tfe_database_password"></a> [tfe\_database\_password](#output\_tfe\_database\_password) | Database password. |
| <a name="output_tfe_database_user"></a> [tfe\_database\_user](#output\_tfe\_database\_user) | Database user. |
| <a name="output_tfe_object_storage_azure_account_name"></a> [tfe\_object\_storage\_azure\_account\_name](#output\_tfe\_object\_storage\_azure\_account\_name) | Storage account name. |
| <a name="output_tfe_object_storage_azure_client_id"></a> [tfe\_object\_storage\_azure\_client\_id](#output\_tfe\_object\_storage\_azure\_client\_id) | Workload identity client ID for Blob access. |
| <a name="output_tfe_object_storage_azure_container"></a> [tfe\_object\_storage\_azure\_container](#output\_tfe\_object\_storage\_azure\_container) | Blob container name. |
| <a name="output_tfe_pod_requests"></a> [tfe\_pod\_requests](#output\_tfe\_pod\_requests) | TFE pod CPU and memory requests for this size. The lab preset is below the chart default so the pod fits Standard\_D4ds\_v5 nodes. |
| <a name="output_tfe_redis_host"></a> [tfe\_redis\_host](#output\_tfe\_redis\_host) | Main Redis hostname (no port). |
| <a name="output_tfe_redis_password"></a> [tfe\_redis\_password](#output\_tfe\_redis\_password) | Main Redis access key. |
| <a name="output_tfe_redis_sidekiq_host"></a> [tfe\_redis\_sidekiq\_host](#output\_tfe\_redis\_sidekiq\_host) | Sidekiq Redis hostname (no port). |
| <a name="output_tfe_redis_sidekiq_password"></a> [tfe\_redis\_sidekiq\_password](#output\_tfe\_redis\_sidekiq\_password) | Sidekiq Redis access key. |
| <a name="output_tfe_redis_sidekiq_use_auth"></a> [tfe\_redis\_sidekiq\_use\_auth](#output\_tfe\_redis\_sidekiq\_use\_auth) | Sidekiq Redis auth flag. |
| <a name="output_tfe_redis_use_auth"></a> [tfe\_redis\_use\_auth](#output\_tfe\_redis\_use\_auth) | Main Redis auth flag. |
<!-- END_TF_DOCS -->
