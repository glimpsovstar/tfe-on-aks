# tfe-bootstrap

Creates the first Terraform Enterprise site admin and stores its credentials in Key Vault. It:

- generates the admin password (`random_password`);
- calls `POST https://<tfe_hostname>/admin/initial-admin-user?token=<IACT>` once, through the `devops-rob/terracurl` provider;
- stores the returned API token and the password in Key Vault as `tfe-admin-token` and `tfe-admin-password`.

## Warnings

- The IACT (initial admin creation token) is only valid for 60 minutes after TFE starts. If it has expired, run `kubectl rollout restart deployment/terraform-enterprise -n tfe` to reopen the window, then re-run the Stack.
- The request is made exactly once. `skip_read` and `skip_destroy` are set, and `lifecycle.ignore_changes` covers the URL, query string, headers and body version, so a later plan does not replace the resource and re-POST.
- Destroy forgets the admin; it does not delete it. The admin user stays in TFE after `terraform destroy`.
- The request body is write-only (`request_body_wo`), which needs Terraform 1.11 or later.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.67 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.9 |
| <a name="requirement_terracurl"></a> [terracurl](#requirement\_terracurl) | ~> 2.11 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_terracurl"></a> [terracurl](#provider\_terracurl) | 2.11.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_key_vault_secret.admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.admin_token](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [random_password.admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terracurl_request.initial_admin](https://registry.terraform.io/providers/devops-rob/terracurl/latest/docs/resources/request) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_admin_email"></a> [admin\_email](#input\_admin\_email) | Email of the first site admin. | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Username of the first site admin. | `string` | `"tfeadmin"` | no |
| <a name="input_iact_token"></a> [iact\_token](#input\_iact\_token) | Initial admin creation token (IACT) from the TFE pod. | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | Key Vault that receives the admin token and password. | `string` | n/a | yes |
| <a name="input_tfe_hostname"></a> [tfe\_hostname](#input\_tfe\_hostname) | TFE hostname; the initial admin endpoint is called on it. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_admin_token"></a> [admin\_token](#output\_admin\_token) | API token of the first site admin. |
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | First site admin username. |
<!-- END_TF_DOCS -->
