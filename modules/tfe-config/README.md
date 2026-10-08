# tfe-config

Configures a fresh Terraform Enterprise instance with the `hashicorp/tfe` provider (configured by the caller). It creates:

- the organization, with cost estimation off (TFE has no egress to `prices.azure.com`);
- the `platform` project plus any extra projects passed in `projects`;
- organization memberships for every owner and platform engineer email;
- the `platform` team with admin access to the `platform` project.

## Notes

- TFE creates the `owners` team together with the organization, so it is read with a data source and cannot be created with `tfe_team`.
- Owners are added one by one with `tfe_team_organization_member`, which is non-authoritative. The authoritative `tfe_team_organization_members` would remove the bootstrap admin from `owners`.
- Invited users must accept by email or SSO before they become active members.

## Security

The module is secure by default: `collaborator_auth_policy` defaults to `two_factor_mandatory`.

Every organization owner, including the bootstrap admin, must enrol 2FA before that setting can apply. If any owner has not, the apply fails with an API error. See [Two-factor authentication](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/2fa).

The sample Stack deployment sets `collaborator_auth_policy = "password"` explicitly in `deployments.tfdeploy.hcl`. Its `tfe` provider uses the bootstrap admin's user token, which has no 2FA. Switch the deployment to `two_factor_mandatory` once every owner has enrolled 2FA, or move to SSO.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_tfe"></a> [tfe](#requirement\_tfe) | ~> 0.81 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_tfe"></a> [tfe](#provider\_tfe) | 0.81.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [tfe_organization.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization) | resource |
| [tfe_organization_membership.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/organization_membership) | resource |
| [tfe_project.this](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/project) | resource |
| [tfe_team.platform](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team) | resource |
| [tfe_team_organization_member.owners](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_organization_member) | resource |
| [tfe_team_organization_member.platform](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_organization_member) | resource |
| [tfe_team_project_access.platform](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/resources/team_project_access) | resource |
| [tfe_team.owners](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs/data-sources/team) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_collaborator_auth_policy"></a> [collaborator\_auth\_policy](#input\_collaborator\_auth\_policy) | Organization sign-in policy: password or two\_factor\_mandatory. Secure by default; set "password" only for labs whose automation token user has no 2FA (see README Security). | `string` | `"two_factor_mandatory"` | no |
| <a name="input_organization_email"></a> [organization\_email](#input\_organization\_email) | Admin email for the organization. | `string` | n/a | yes |
| <a name="input_organization_name"></a> [organization\_name](#input\_organization\_name) | TFE organization name. | `string` | n/a | yes |
| <a name="input_owners_member_emails"></a> [owners\_member\_emails](#input\_owners\_member\_emails) | Emails added to the owners team. | `list(string)` | `[]` | no |
| <a name="input_platform_team_member_emails"></a> [platform\_team\_member\_emails](#input\_platform\_team\_member\_emails) | Emails added to the platform team. | `list(string)` | `[]` | no |
| <a name="input_projects"></a> [projects](#input\_projects) | Extra project names (platform is always created). | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_organization_name"></a> [organization\_name](#output\_organization\_name) | Organization name. |
| <a name="output_platform_team_id"></a> [platform\_team\_id](#output\_platform\_team\_id) | platform team ID. |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | Project IDs by name. |
<!-- END_TF_DOCS -->
