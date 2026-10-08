terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.67" }
    tfe     = { source = "hashicorp/tfe", version = "~> 0.81" }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Written by modules/tfe-bootstrap during 02-app. A data source is read at plan time, so the token is known when the tfe provider configures.
data "azurerm_key_vault_secret" "admin_token" {
  name         = "tfe-admin-token"
  key_vault_id = var.key_vault_id
}

provider "tfe" {
  hostname = var.tfe_hostname
  token    = data.azurerm_key_vault_secret.admin_token.value
}
