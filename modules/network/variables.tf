variable "prefix" {
  type        = string
  description = "Short lowercase name prefix (3-10 letters/digits, must not contain 'tfe')."
  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.prefix)) && !strcontains(var.prefix, "tfe")
    error_message = "prefix must be 3-10 lowercase letters or digits and must not contain 'tfe'."
  }
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "australiaeast"
}

variable "resource_group_name" {
  type        = string
  description = "Existing resource group for all network resources."
}

variable "vnet_cidr" {
  type        = string
  description = "VNet address space."
  default     = "10.40.0.0/16"
}

variable "subnet_cidrs" {
  type = object({
    lb    = string
    aks   = string
    db    = string
    redis = string
    agent = string
  })
  description = "Subnet CIDRs. AKS uses Azure CNI, so its subnet must hold nodes, TFE pods and peak agent pods."
  default = {
    lb    = "10.40.0.0/24"
    db    = "10.40.1.0/24"
    redis = "10.40.2.0/24"
    agent = "10.40.3.0/24"
    aks   = "10.40.4.0/22"
  }
}

variable "public_dns_zone_name" {
  type        = string
  description = "Existing public Azure DNS zone the user owns, e.g. example.com."
}

variable "lab_subdomain" {
  type        = string
  description = "Subdomain for TFE. The hostname becomes tfe.<lab_subdomain>.<public_dns_zone_name>."
  default     = "tfelab"
}

variable "operator_cidrs" {
  type        = list(string)
  description = "Operator public IPs as /32 CIDRs (Key Vault firewall)."
  validation {
    condition     = alltrue([for c in var.operator_cidrs : can(cidrhost(c, 0)) && endswith(c, "/32")])
    error_message = "operator_cidrs entries must be single-host CIDRs like 203.0.113.10/32."
  }
}

variable "secrets_officer_principal_ids" {
  type        = map(string)
  description = "Principals that get Key Vault Secrets Officer, keyed by a static label (values may be unknown at plan)."
}

variable "tags" {
  type        = map(string)
  description = "Tags for every resource."
  default     = {}
}
