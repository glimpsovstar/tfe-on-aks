variable "organization_name" {
  type        = string
  description = "TFE organization name."
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{3,40}$", var.organization_name))
    error_message = "organization_name: 3-40 letters, digits, '-' or '_', no spaces."
  }
}
variable "organization_email" {
  type        = string
  description = "Admin email for the organization."
}
variable "projects" {
  type        = list(string)
  default     = []
  description = "Extra project names (platform is always created)."
}
variable "owners_member_emails" {
  type        = list(string)
  default     = []
  description = "Emails added to the owners team."
}
variable "platform_team_member_emails" {
  type        = list(string)
  default     = []
  description = "Emails added to the platform team."
}
variable "collaborator_auth_policy" {
  type        = string
  default     = "two_factor_mandatory"
  description = "Organization sign-in policy: password or two_factor_mandatory. Secure by default; set \"password\" only for labs whose automation token user has no 2FA (see README Security)."
  validation {
    condition     = contains(["password", "two_factor_mandatory"], var.collaborator_auth_policy)
    error_message = "collaborator_auth_policy must be \"password\" or \"two_factor_mandatory\"."
  }
}
