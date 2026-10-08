provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Used only for the NS delegation record in the parent public DNS zone, which may live in a
# different subscription from the lab.
provider "azurerm" {
  alias = "parent_dns"
  features {}
  subscription_id = coalesce(var.public_dns_zone_subscription_id, var.subscription_id)
}

# Authenticates with TFE_TOKEN (HCP Terraform user or team token) from the environment.
provider "tfe" {
  hostname     = "app.terraform.io"
  organization = var.hcp_organization
}
