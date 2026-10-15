variable "prefix" {
  type        = string
  description = "Name prefix for resources (3-10 lowercase alphanumerics, no 'tfe')."
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.prefix)) && !strcontains(var.prefix, "tfe")
    error_message = "prefix must be 3-10 lowercase letters or digits and must not contain 'tfe'."
  }
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
variable "tfe_version" {
  type        = string
  default     = "2.0.8"
  description = "TFE semver, 1.0.1 or later (selects Azure Managed Redis in the HVD module)."
  validation {
    condition     = can(regex("^(1\\.0\\.[1-9][0-9]*|1\\.[1-9][0-9]*\\.[0-9]+|[2-9][0-9]*\\.[0-9]+\\.[0-9]+)$", var.tfe_version))
    error_message = "tfe_version must be semver X.Y.Z, 1.0.1 or later, without a 'v' prefix."
  }
}
variable "aks_kubernetes_version" {
  type        = string
  default     = null
  description = "AKS version supported in the region and by TFE (az aks get-versions -l australiaeast). Required when create_aks_cluster = true."
}
variable "size" {
  type        = string
  default     = "lab"
  description = "Sizing preset: lab, small or production."
  validation {
    condition     = contains(["lab", "small", "production"], var.size)
    error_message = "size must be lab, small or production."
  }
}
variable "aks_authorized_cidrs" {
  type        = list(string)
  description = "/32 CIDRs allowed on the AKS API (agent IP + operators)."
  validation {
    condition     = length(var.aks_authorized_cidrs) > 0 && alltrue([for c in var.aks_authorized_cidrs : can(cidrhost(c, 0)) && endswith(c, "/32")])
    error_message = "aks_authorized_cidrs must contain at least one /32 CIDR, and every entry must be a /32."
  }
}
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to all resources."
}
variable "create_aks_cluster" {
  type        = bool
  default     = true
  description = "true: the HVD module creates the AKS cluster. false: deploy TFE on an existing cluster named in existing_aks_cluster_name."
}
variable "existing_aks_cluster_name" {
  type        = string
  default     = null
  description = "Existing AKS cluster for TFE (create_aks_cluster = false). It must have the OIDC issuer and workload identity enabled."
}
variable "existing_aks_resource_group_name" {
  type        = string
  default     = null
  description = "Resource group of the existing AKS cluster. Defaults to resource_group_name."
}
