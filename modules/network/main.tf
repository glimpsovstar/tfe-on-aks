data "azurerm_client_config" "current" {}

locals {
  private_dns_zone_name = "${var.lab_subdomain}.${var.public_dns_zone_name}"
  tfe_hostname          = "tfe.${local.private_dns_zone_name}"
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "lb" {
  name                 = "${var.prefix}-lb"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidrs.lb]
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.prefix}-aks"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidrs.aks]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"]
}

resource "azurerm_subnet" "db" {
  name                 = "${var.prefix}-db"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidrs.db]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "postgres"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "redis" {
  name                              = "${var.prefix}-redis"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = [var.subnet_cidrs.redis]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "agent" {
  name                 = "${var.prefix}-agent"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidrs.agent]
  # KeyVault is the only service endpoint the agent subnet needs. Azure storage IP rules do not
  # apply to same-region traffic, so the agent's public IP is not what lets it reach Blob. In
  # steady state it uses the HVD private endpoint and the privatelink.blob zone linked to this VNet.
  service_endpoints = ["Microsoft.KeyVault"]
}

resource "random_string" "kv_suffix" {
  length  = 4
  upper   = false
  special = false
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault" "this" {
  name                       = "${var.prefix}kv${random_string.kv_suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.operator_cidrs
    virtual_network_subnet_ids = [azurerm_subnet.aks.id, azurerm_subnet.agent.id]
  }
}

resource "azurerm_role_assignment" "secrets_officer" {
  for_each             = var.secrets_officer_principal_ids
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

# Azure RBAC takes time to propagate before the first data-plane write succeeds.
resource "time_sleep" "rbac_propagation" {
  create_duration = "60s"
  depends_on      = [azurerm_role_assignment.secrets_officer]
}

resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "-_"
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "db_password" {
  name         = "tfe-db-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [time_sleep.rbac_propagation]
}

resource "azurerm_private_dns_zone" "tfe" {
  name                = local.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "tfe" {
  name                  = "${var.prefix}-tfe-zone-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.tfe.name
  virtual_network_id    = azurerm_virtual_network.this.id
}
