variable "identity_token" {
  type      = string
  ephemeral = true
}
variable "client_id" { type = string }
variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "prefix" { type = string }
variable "vnet_id" { type = string }
variable "lb_subnet_id" { type = string }
variable "lb_subnet_name" { type = string }
variable "aks_subnet_id" { type = string }
variable "db_subnet_id" { type = string }
variable "redis_subnet_id" { type = string }
variable "key_vault_id" { type = string }
variable "db_password_secret_name" { type = string }
variable "private_dns_zone_name" { type = string }
variable "public_dns_zone_name" { type = string }
variable "public_dns_zone_resource_group" { type = string }
variable "tfe_hostname" { type = string }
variable "lb_static_ip" { type = string }
variable "aks_authorized_cidrs_csv" { type = string }
variable "owner_tag" { type = string }
variable "expires_tag" { type = string }
variable "tfe_license" {
  type      = string
  sensitive = true
}
variable "tfe_version" {
  type    = string
  default = "2.0.8"
}
variable "aks_kubernetes_version" { type = string }
variable "size" {
  type    = string
  default = "lab"
}
variable "admin_email" { type = string }
variable "organization_name" { type = string }
variable "organization_email" { type = string }
variable "platform_team_member_emails" {
  type    = list(string)
  default = []
}
variable "collaborator_auth_policy" { type = string }

variable "configure_tfe" {
  type        = bool
  default     = false
  description = "Second pass. When true, the tfe_config component creates the organization, projects and team. Leave false until tfe_bootstrap has applied, because the tfe provider needs the admin token at plan time."
}
