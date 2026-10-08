variable "state_resource_group_name" {
  type        = string
  description = "Resource group of the state storage account (for 01-infra remote state)."
}

variable "state_storage_account_name" {
  type        = string
  description = "State storage account name (for 01-infra remote state)."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "tfe_hostname" {
  type        = string
  description = "TFE FQDN."
}

variable "tfe_license" {
  type        = string
  description = "TFE license (raw string)."
  sensitive   = true
}

variable "lb_subnet_name" {
  type        = string
  description = "Name of the load balancer subnet."
}

variable "lb_static_ip" {
  type        = string
  description = "Static private IP for the internal load balancer."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID that receives TFE secrets and the admin token."
}

variable "private_dns_zone_name" {
  type        = string
  description = "Private DNS zone name for the TFE hostname."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group of the private DNS zone."
}

variable "public_dns_zone_name" {
  type        = string
  description = "Public DNS zone used for the ACME DNS-01 challenge."
}

variable "public_dns_zone_resource_group" {
  type        = string
  description = "Resource group of the public DNS zone."
}

variable "acme_azure_auth_method" {
  type        = string
  default     = "msi"
  description = "lego azuredns auth: msi on the agent VM, cli on a laptop."
  validation {
    condition     = contains(["msi", "cli"], var.acme_azure_auth_method)
    error_message = "acme_azure_auth_method must be msi or cli."
  }
}

variable "admin_email" {
  type        = string
  description = "Email of the first site admin and the organization."
}
