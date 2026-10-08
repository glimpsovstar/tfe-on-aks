variable "tfe_hostname" {
  type        = string
  description = "TFE hostname; the initial admin endpoint is called on it."
}
variable "iact_token" {
  type        = string
  sensitive   = true
  description = "Initial admin creation token (IACT) from the TFE pod."
}
variable "admin_username" {
  type        = string
  default     = "tfeadmin"
  description = "Username of the first site admin."
}
variable "admin_email" {
  type        = string
  description = "Email of the first site admin."
}
variable "key_vault_id" {
  type        = string
  description = "Key Vault that receives the admin token and password."
}
