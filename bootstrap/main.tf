data "azurerm_client_config" "current" {}

locals {
  tags = {
    owner      = var.owner_tag
    expires    = var.expires_tag
    project    = "tf-azure-aks-tfe"
    managed_by = "terraform-bootstrap"
  }
}

# This lab is destroyed by design, so prevent_destroy is deliberately not set.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_resource_group" "this" {
  name     = "${var.prefix}-tfe-rg"
  location = var.location
  tags     = local.tags
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_user_assigned_identity" "stack" {
  name                = "${var.prefix}-stack-id"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_federated_identity_credential" "stack" {
  for_each                  = toset(["plan", "apply"])
  name                      = "${var.stack_name}-${var.deployment_name}-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.stack.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://app.terraform.io"
  subject                   = "organization:${var.hcp_organization}:project:${var.hcp_project}:stack:${var.stack_name}:deployment:${var.deployment_name}:operation:${each.key}"
}

resource "azurerm_consumption_budget_resource_group" "lab" {
  name              = "${var.prefix}-lab-budget"
  resource_group_id = azurerm_resource_group.this.id
  amount            = var.budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    contact_emails = var.budget_contact_emails
  }

  notification {
    enabled        = true
    threshold      = 90
    operator       = "GreaterThan"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

resource "azurerm_role_assignment" "stack_rg" {
  for_each             = toset(["Contributor", "User Access Administrator"])
  scope                = azurerm_resource_group.this.id
  role_definition_name = each.key
  principal_id         = azurerm_user_assigned_identity.stack.principal_id
}

module "network" {
  source = "../modules/network"

  prefix               = var.prefix
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  public_dns_zone_name = var.public_dns_zone_name
  lab_subdomain        = var.lab_subdomain
  operator_cidrs       = var.operator_cidrs
  secrets_officer_principal_ids = {
    operator = data.azurerm_client_config.current.object_id
    stack    = azurerm_user_assigned_identity.stack.principal_id
  }
  tags = local.tags
}
