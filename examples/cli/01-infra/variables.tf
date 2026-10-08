variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}
variable "prefix" {
  type        = string
  description = "Name prefix for resources (3-10 lowercase alphanumerics, no 'tfe')."
}
variable "location" {
  type        = string
  default     = "australiaeast"
  description = "Azure region."
}
variable "resource_group_name" {
  type        = string
  description = "Existing resource group to deploy into."
}
variable "vnet_id" {
  type        = string
  description = "Virtual network ID."
}
variable "lb_subnet_id" {
  type        = string
  description = "Load balancer subnet ID."
}
variable "aks_subnet_id" {
  type        = string
  description = "AKS node subnet ID."
}
variable "db_subnet_id" {
  type        = string
  description = "PostgreSQL delegated subnet ID."
}
variable "redis_subnet_id" {
  type        = string
  description = "Redis private endpoint subnet ID."
}
variable "key_vault_id" {
  type        = string
  description = "Key Vault ID holding the database password secret."
}
variable "db_password_secret_name" {
  type        = string
  description = "Name of the Key Vault secret with the database password."
}
variable "tfe_hostname" {
  type        = string
  description = "TFE FQDN."
}
variable "aks_kubernetes_version" {
  type        = string
  description = "AKS version supported in the region and by TFE (az aks get-versions -l australiaeast)."
}
variable "size" {
  type        = string
  default     = "lab"
  description = "Sizing preset: lab, small or production."
}
variable "aks_authorized_cidrs" {
  type        = list(string)
  description = "/32 CIDRs allowed on the AKS API (agent IP + operators)."
}
