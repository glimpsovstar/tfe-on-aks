variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID holding the tfe-admin-token secret."
}

variable "tfe_hostname" {
  type        = string
  description = "TFE FQDN."
}

variable "organization_name" {
  type        = string
  description = "TFE organization name."
}

variable "organization_email" {
  type        = string
  description = "Email address of the TFE organization."
}

variable "collaborator_auth_policy" {
  type        = string
  description = "Organization sign-in policy: password or two_factor_mandatory."
  validation {
    condition     = contains(["password", "two_factor_mandatory"], var.collaborator_auth_policy)
    error_message = "collaborator_auth_policy must be \"password\" or \"two_factor_mandatory\"."
  }
}
