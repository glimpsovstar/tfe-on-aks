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

# The Stack creates resources (Contributor) and two role assignments made by the HVD module:
# Network Contributor (AKS identity on its subnets) and Storage Blob Data Owner (TFE identity on Blob).
# Instead of User Access Administrator, which could grant any role (including Owner) in this resource
# group, it gets Role Based Access Control Administrator limited by an ABAC condition to those two roles.
locals {
  stack_assignable_role_ids = [
    "4d97b98b-1d4f-4787-a291-c67834d212e7", # Network Contributor
    "b7e6dc6d-f1e8-4753-8033-0f276bb0955b", # Storage Blob Data Owner
  ]
  stack_rbac_condition = <<-EOT
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
     )
     OR
     (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.stack_assignable_role_ids)}}
     )
    )
    AND
    (
     (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
     )
     OR
     (
      @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", local.stack_assignable_role_ids)}}
     )
    )
  EOT
}

resource "azurerm_role_assignment" "stack_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.stack.principal_id
}

resource "azurerm_role_assignment" "stack_rbac_admin" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azurerm_user_assigned_identity.stack.principal_id
  condition_version    = "2.0"
  condition            = local.stack_rbac_condition
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
