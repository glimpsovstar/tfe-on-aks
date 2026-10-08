variable "prefix" {
  type        = string
  description = "Short lowercase prefix (3-10 letters/digits, no 'tfe')."
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.prefix)) && !strcontains(var.prefix, "tfe")
    error_message = "prefix must be 3-10 lowercase letters or digits and must not contain 'tfe'."
  }
}
variable "location" {
  type        = string
  default     = "australiaeast"
  description = "Azure region for the lab."
}
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID to deploy into."
}
variable "operator_cidrs" {
  type        = list(string)
  description = "Your laptop's public egress IP as /32. Must still match when you destroy."
}
variable "public_dns_zone_name" {
  type        = string
  description = "Existing parent public Azure DNS zone (e.g. example.com). Bootstrap adds one NS delegation for the lab subdomain here; nothing else is written to it."
}
variable "public_dns_zone_resource_group" {
  type        = string
  description = "Resource group holding the parent public DNS zone."
}
variable "public_dns_zone_subscription_id" {
  type        = string
  default     = null
  description = "Subscription that holds the parent public DNS zone. Defaults to subscription_id when null."
}
variable "create_lab_delegation" {
  type        = bool
  default     = true
  description = "Create the NS delegation record in the parent zone. Set false when the parent zone is in another tenant, then add the record by hand using the lab_dns_zone_name_servers output."
}
variable "lab_subdomain" {
  type        = string
  default     = "tfelab"
  description = "Subdomain under the public zone used for the TFE hostname."
}
variable "hcp_organization" {
  type        = string
  description = "HCP Terraform organization name."
}
variable "hcp_project" {
  type        = string
  default     = "tfe-on-aks"
  description = "HCP Terraform project that holds the Stack."
}
variable "stack_name" {
  type        = string
  default     = "tfe-aks"
  description = "Name of the HCP Terraform Stack."
}
variable "deployment_name" {
  type        = string
  default     = "main"
  description = "Stack deployment name (appears in the OIDC subject)."
}
variable "varset_name" {
  type        = string
  default     = "tfe-aks-inputs"
  description = "Name of the variable set that carries Stack inputs."
}
variable "create_stack" {
  type        = bool
  default     = true
  description = "Create the HCP Terraform Stack with tfe_stack (beta). Set false to create it by hand."
}
variable "github_repo" {
  type        = string
  default     = "your-org/tfe-on-aks"
  description = "GitHub repository (owner/name) that holds the Stack configuration."
}
variable "github_branch" {
  type        = string
  default     = "main"
  description = "Branch the Stack tracks."
}
variable "github_app_installation_id" {
  type        = string
  default     = null
  description = "HCP Terraform GitHub App installation ID (ghain-...). Find it in HCP Terraform under Settings > Version Control or with data source tfe_github_app_installation. Use this or vcs_oauth_token_id."
}
variable "vcs_oauth_token_id" {
  type        = string
  default     = null
  description = "HCP Terraform VCS OAuth token ID (ot-...) for a classic GitHub OAuth connection. Use this or github_app_installation_id."

  validation {
    condition     = !var.create_stack || (var.vcs_oauth_token_id == null) != (var.github_app_installation_id == null)
    error_message = "When create_stack is true, set exactly one of vcs_oauth_token_id and github_app_installation_id."
  }
}
variable "tfe_license_file" {
  type        = string
  description = "Path to the TFE .hclic licence file on this machine."
}
variable "agent_vm_size" {
  type        = string
  default     = "Standard_B2ls_v2"
  description = "Size of the HCP Terraform agent VM."
}
variable "tfc_agent_version" {
  type        = string
  description = "tfc-agent version; must be 1.25.2 or later for Stacks."
}
variable "enable_agent_ssh" {
  type        = bool
  default     = false
  description = "Open SSH (22) to operator_cidrs on the agent VM."
}
variable "owner_tag" {
  type        = string
  description = "Value of the owner tag."
}
variable "expires_tag" {
  type        = string
  description = "Date the lab should be destroyed by (YYYY-MM-DD)."
}
variable "budget_amount" {
  type        = number
  default     = 500
  description = "Monthly budget for the lab resource group, in the subscription's billing currency."
}
variable "budget_contact_emails" {
  type        = list(string)
  description = "Who gets the budget alerts."
}
variable "enable_demo_vpn" {
  type        = bool
  default     = false
  description = "Create the optional demo access path: point-to-site VPN gateway plus DNS Private Resolver inbound endpoint, so a laptop can open the private TFE URL. Costs about A$0.60/h while on."
}
variable "demo_vpn_gateway_subnet_cidr" {
  type        = string
  default     = "10.40.255.0/27"
  description = "CIDR of the GatewaySubnet in the lab VNet (demo VPN). Must be free inside the VNet."
}
variable "demo_vpn_resolver_subnet_cidr" {
  type        = string
  default     = "10.40.254.0/28"
  description = "CIDR of the DNS Private Resolver inbound subnet in the lab VNet (demo VPN). The endpoint takes the fourth address."
}
variable "demo_vpn_client_address_pool" {
  type        = string
  default     = "172.16.201.0/24"
  description = "Address pool handed to VPN clients. Must not overlap the VNet or your local network."
}
variable "demo_vpn_gateway_sku" {
  type        = string
  default     = "VpnGw1AZ"
  description = "VPN gateway SKU. Use an AZ SKU; the non-AZ SKUs are being retired."
}
variable "demo_vpn_cert_validity_hours" {
  type        = number
  default     = 720
  description = "Validity of the demo root CA and client certificates, in hours."
}
