# tfe-install

Installs Terraform Enterprise on an existing AKS cluster. It creates:

- the `tfe` namespace;
- the `tfe-secrets` secret (licence, encryption password, database and Redis passwords, IACT token), with the generated values also stored in Key Vault;
- the `terraform-enterprise` image pull secret for `images.releases.hashicorp.com`;
- a Let's Encrypt certificate via DNS-01 (`azuredns`), using the agent's managed identity against the public DNS zone passed in, stored as the `tfe-certs` TLS secret and in Key Vault;
- a private DNS A record for the TFE hostname pointing at the internal load balancer IP;
- the `terraform-enterprise` Helm release, pinned to `chart_version`, which waits up to 15 minutes for ready pods.

## Warnings

- Never change the ACME server URL on an existing deployment; it is set on the provider in the Stack. The ACME account is tied to the directory, so changing it breaks `acme_registration`.
- Let's Encrypt staging can only be chosen at first deploy. Switching between staging and production later requires recreating `acme_registration` (and the certificate). The Stack sets production (`https://acme-v02.api.letsencrypt.org/directory`) in `providers.tfcomponent.hcl`; if you want staging for a first iteration, change it there before the first apply.
- Let's Encrypt allows 5 duplicate certificates per week. Repeated destroy and apply cycles of the same hostname can hit that limit. Use staging from the very first deploy if you expect to iterate.
- `namespace` must stay `tfe`: the HVD workload-identity subject is fixed to `system:serviceaccount:tfe:tfe`, and the chart names the service account after the namespace.
- The ACME pre-check uses public resolvers (8.8.8.8, 1.1.1.1) because the private zone shadows the lab subdomain inside the VNet.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_acme"></a> [acme](#requirement\_acme) | ~> 3.2 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.67 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.3 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.3 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.9 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_acme"></a> [acme](#provider\_acme) | 3.2.1 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.3.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 3.3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [acme_certificate.tfe](https://registry.terraform.io/providers/vancluever/acme/latest/docs/resources/certificate) | resource |
| [acme_registration.this](https://registry.terraform.io/providers/vancluever/acme/latest/docs/resources/registration) | resource |
| [azurerm_key_vault_secret.encryption](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.iact](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.tls_fullchain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.tls_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_private_dns_a_record.tfe](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_a_record) | resource |
| [helm_release.tfe](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.tfe](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.pull](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.tfe_certs](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [kubernetes_secret_v1.tfe_secrets](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [random_password.encryption](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.iact](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acme_azure_auth_method"></a> [acme\_azure\_auth\_method](#input\_acme\_azure\_auth\_method) | lego azuredns auth: msi on the agent VM, cli on a laptop. | `string` | `"msi"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | n/a | `string` | `"2.0.8"` | no |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | n/a | `string` | n/a | yes |
| <a name="input_lb_static_ip"></a> [lb\_static\_ip](#input\_lb\_static\_ip) | n/a | `string` | n/a | yes |
| <a name="input_lb_subnet_name"></a> [lb\_subnet\_name](#input\_lb\_subnet\_name) | n/a | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | n/a | `string` | `"tfe"` | no |
| <a name="input_pod_requests"></a> [pod\_requests](#input\_pod\_requests) | TFE pod CPU and memory requests. The default is the chart default (4 vCPU, 8Gi); the lab preset lowers it so the pod schedules on Standard\_D4ds\_v5 nodes. | `object({ cpu = string, memory = string })` | <pre>{<br/>  "cpu": "4",<br/>  "memory": "8Gi"<br/>}</pre> | no |
| <a name="input_private_dns_zone_name"></a> [private\_dns\_zone\_name](#input\_private\_dns\_zone\_name) | n/a | `string` | n/a | yes |
| <a name="input_public_dns_zone_name"></a> [public\_dns\_zone\_name](#input\_public\_dns\_zone\_name) | n/a | `string` | n/a | yes |
| <a name="input_public_dns_zone_resource_group"></a> [public\_dns\_zone\_resource\_group](#input\_public\_dns\_zone\_resource\_group) | n/a | `string` | n/a | yes |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | n/a | `number` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | n/a | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | n/a | `string` | n/a | yes |
| <a name="input_tfe_database_host"></a> [tfe\_database\_host](#input\_tfe\_database\_host) | n/a | `string` | n/a | yes |
| <a name="input_tfe_database_name"></a> [tfe\_database\_name](#input\_tfe\_database\_name) | n/a | `string` | n/a | yes |
| <a name="input_tfe_database_password"></a> [tfe\_database\_password](#input\_tfe\_database\_password) | n/a | `string` | n/a | yes |
| <a name="input_tfe_database_user"></a> [tfe\_database\_user](#input\_tfe\_database\_user) | n/a | `string` | n/a | yes |
| <a name="input_tfe_hostname"></a> [tfe\_hostname](#input\_tfe\_hostname) | n/a | `string` | n/a | yes |
| <a name="input_tfe_license"></a> [tfe\_license](#input\_tfe\_license) | n/a | `string` | n/a | yes |
| <a name="input_tfe_object_storage_azure_account_name"></a> [tfe\_object\_storage\_azure\_account\_name](#input\_tfe\_object\_storage\_azure\_account\_name) | n/a | `string` | n/a | yes |
| <a name="input_tfe_object_storage_azure_client_id"></a> [tfe\_object\_storage\_azure\_client\_id](#input\_tfe\_object\_storage\_azure\_client\_id) | n/a | `string` | n/a | yes |
| <a name="input_tfe_object_storage_azure_container"></a> [tfe\_object\_storage\_azure\_container](#input\_tfe\_object\_storage\_azure\_container) | n/a | `string` | n/a | yes |
| <a name="input_tfe_redis_host"></a> [tfe\_redis\_host](#input\_tfe\_redis\_host) | n/a | `string` | n/a | yes |
| <a name="input_tfe_redis_password"></a> [tfe\_redis\_password](#input\_tfe\_redis\_password) | n/a | `string` | n/a | yes |
| <a name="input_tfe_redis_sidekiq_host"></a> [tfe\_redis\_sidekiq\_host](#input\_tfe\_redis\_sidekiq\_host) | n/a | `string` | n/a | yes |
| <a name="input_tfe_redis_sidekiq_password"></a> [tfe\_redis\_sidekiq\_password](#input\_tfe\_redis\_sidekiq\_password) | n/a | `string` | n/a | yes |
| <a name="input_tfe_redis_sidekiq_use_auth"></a> [tfe\_redis\_sidekiq\_use\_auth](#input\_tfe\_redis\_sidekiq\_use\_auth) | n/a | `bool` | n/a | yes |
| <a name="input_tfe_redis_use_auth"></a> [tfe\_redis\_use\_auth](#input\_tfe\_redis\_use\_auth) | n/a | `bool` | n/a | yes |
| <a name="input_tfe_version"></a> [tfe\_version](#input\_tfe\_version) | n/a | `string` | `"2.0.8"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_helm_values_yaml"></a> [helm\_values\_yaml](#output\_helm\_values\_yaml) | Rendered Helm values (no secrets). |
| <a name="output_iact_token"></a> [iact\_token](#output\_iact\_token) | Preset initial admin creation token. |
| <a name="output_tfe_hostname"></a> [tfe\_hostname](#output\_tfe\_hostname) | TFE hostname (for the tfe provider). |
| <a name="output_tfe_url"></a> [tfe\_url](#output\_tfe\_url) | TFE URL. |
<!-- END_TF_DOCS -->
