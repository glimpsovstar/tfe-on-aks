# network

VNet, five subnets, Key Vault (RBAC, default deny), the TFE database password, and a private DNS zone for the lab subdomain. Subnets follow the AKS HVD module prerequisites.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.67 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.9 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.14 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.14.2 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.db_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_dns_zone.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_role_assignment.secrets_officer](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.agent](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.aks](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.db](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.lb](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.redis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [random_password.db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_string.kv_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.rbac_propagation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_lab_subdomain"></a> [lab\_subdomain](#input\_lab\_subdomain) | Subdomain for TFE. The hostname becomes tfe.<lab\_subdomain>.<public\_dns\_zone\_name>. | `string` | `"tfelab"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region. | `string` | `"australiaeast"` | no |
| <a name="input_operator_cidrs"></a> [operator\_cidrs](#input\_operator\_cidrs) | Operator public IPs as /32 CIDRs (Key Vault firewall). | `list(string)` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Short lowercase name prefix (3-10 letters/digits, must not contain 'tfe'). | `string` | n/a | yes |
| <a name="input_public_dns_zone_name"></a> [public\_dns\_zone\_name](#input\_public\_dns\_zone\_name) | Existing public Azure DNS zone the user owns, e.g. example.com. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Existing resource group for all network resources. | `string` | n/a | yes |
| <a name="input_secrets_officer_principal_ids"></a> [secrets\_officer\_principal\_ids](#input\_secrets\_officer\_principal\_ids) | Principals that get Key Vault Secrets Officer, keyed by a static label (values may be unknown at plan). | `map(string)` | n/a | yes |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | Subnet CIDRs. AKS uses Azure CNI, so its subnet must hold nodes, TFE pods and peak agent pods. | <pre>object({<br/>    lb    = string<br/>    aks   = string<br/>    db    = string<br/>    redis = string<br/>    agent = string<br/>  })</pre> | <pre>{<br/>  "agent": "10.40.3.0/24",<br/>  "aks": "10.40.4.0/22",<br/>  "db": "10.40.1.0/24",<br/>  "lb": "10.40.0.0/24",<br/>  "redis": "10.40.2.0/24"<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for every resource. | `map(string)` | `{}` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | VNet address space. | `string` | `"10.40.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_agent_subnet_id"></a> [agent\_subnet\_id](#output\_agent\_subnet\_id) | Agent subnet ID. |
| <a name="output_aks_subnet_id"></a> [aks\_subnet\_id](#output\_aks\_subnet\_id) | AKS subnet ID. |
| <a name="output_db_password_secret_name"></a> [db\_password\_secret\_name](#output\_db\_password\_secret\_name) | Key Vault secret name holding the TFE database password. |
| <a name="output_db_subnet_id"></a> [db\_subnet\_id](#output\_db\_subnet\_id) | PostgreSQL delegated subnet ID. |
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | Key Vault ID. |
| <a name="output_key_vault_name"></a> [key\_vault\_name](#output\_key\_vault\_name) | Key Vault name (prefix, kv, 4 random chars). |
| <a name="output_lb_static_ip"></a> [lb\_static\_ip](#output\_lb\_static\_ip) | Static private IP for the TFE internal load balancer. |
| <a name="output_lb_subnet_id"></a> [lb\_subnet\_id](#output\_lb\_subnet\_id) | Load balancer subnet ID. |
| <a name="output_lb_subnet_name"></a> [lb\_subnet\_name](#output\_lb\_subnet\_name) | Load balancer subnet name. |
| <a name="output_private_dns_zone_name"></a> [private\_dns\_zone\_name](#output\_private\_dns\_zone\_name) | Private DNS zone name covering the lab subdomain. |
| <a name="output_redis_subnet_id"></a> [redis\_subnet\_id](#output\_redis\_subnet\_id) | Redis private endpoint subnet ID. |
| <a name="output_tfe_hostname"></a> [tfe\_hostname](#output\_tfe\_hostname) | TFE FQDN: tfe.<lab\_subdomain>.<public\_dns\_zone\_name>. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Virtual network ID. |
<!-- END_TF_DOCS -->
