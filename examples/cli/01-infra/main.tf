terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.67" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "tfe_infra" {
  source = "../../../modules/tfe-infra"

  prefix                  = var.prefix
  location                = var.location
  resource_group_name     = var.resource_group_name
  vnet_id                 = var.vnet_id
  lb_subnet_id            = var.lb_subnet_id
  aks_subnet_id           = var.aks_subnet_id
  db_subnet_id            = var.db_subnet_id
  redis_subnet_id         = var.redis_subnet_id
  key_vault_id            = var.key_vault_id
  db_password_secret_name = var.db_password_secret_name
  tfe_hostname            = var.tfe_hostname
  aks_kubernetes_version  = var.aks_kubernetes_version
  size                    = var.size
  aks_authorized_cidrs    = var.aks_authorized_cidrs
}
