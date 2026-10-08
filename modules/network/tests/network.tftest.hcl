mock_provider "azurerm" {
  # Mocked IDs must be well-formed Azure resource IDs: the provider validates them in dependent resources.
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/virtualNetworks/tflab-vnet"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/virtualNetworks/tflab-vnet/subnets/mock"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.KeyVault/vaults/tflabkvmock"
    }
  }
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}
mock_provider "random" {
  # The mock otherwise generates 8 chars regardless of the configured length.
  mock_resource "random_string" {
    defaults = {
      result = "ab12"
    }
  }
}
mock_provider "time" {}

variables {
  prefix               = "tflab"
  location             = "australiaeast"
  resource_group_name  = "tflab-tfe-rg"
  public_dns_zone_name = "example.com"
  operator_cidrs       = ["203.0.113.10/32"]
  secrets_officer_principal_ids = {
    operator = "11111111-1111-1111-1111-111111111111"
    stack    = "22222222-2222-2222-2222-222222222222"
  }
  tags = { owner = "test", expires = "2026-10-20" }
}

run "subnets_configured_for_hvd_module" {
  command = apply

  assert {
    condition     = azurerm_subnet.db.delegation[0].service_delegation[0].name == "Microsoft.DBforPostgreSQL/flexibleServers"
    error_message = "DB subnet must be delegated to PostgreSQL Flexible Server."
  }
  assert {
    condition     = alltrue([for e in ["Microsoft.Sql", "Microsoft.Storage", "Microsoft.KeyVault"] : contains(azurerm_subnet.aks.service_endpoints, e)])
    error_message = "AKS subnet needs Sql, Storage and KeyVault service endpoints."
  }
  assert {
    condition     = azurerm_subnet.redis.private_endpoint_network_policies == "Disabled"
    error_message = "Redis subnet must allow private endpoints."
  }
  assert {
    condition     = tolist(azurerm_subnet.agent.service_endpoints) == tolist(["Microsoft.KeyVault"])
    error_message = "Agent subnet needs only the KeyVault endpoint (a Storage endpoint would bypass the storage IP rule)."
  }
}

run "hostname_and_static_ip" {
  command = apply

  assert {
    condition     = output.tfe_hostname == "tfe.tfelab.example.com"
    error_message = "Hostname must be tfe.<lab_subdomain>.<zone>."
  }
  assert {
    condition     = output.private_dns_zone_name == "tfelab.example.com"
    error_message = "Private zone must cover only the lab subdomain."
  }
  assert {
    condition     = output.lb_static_ip == "10.40.0.10"
    error_message = "LB static IP must be host 10 of the LB subnet."
  }
}

run "key_vault_locked_down" {
  command = apply

  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "Key Vault must default-deny."
  }
  assert {
    condition     = azurerm_key_vault.this.rbac_authorization_enabled
    error_message = "Key Vault must use RBAC."
  }
  assert {
    condition     = length(azurerm_role_assignment.secrets_officer) == 2
    error_message = "Both principals get Key Vault Secrets Officer."
  }
  assert {
    condition     = output.db_password_secret_name == "tfe-db-password"
    error_message = "DB password secret name is fixed."
  }
}

run "key_vault_name_has_random_suffix" {
  command = apply

  assert {
    condition     = can(regex("^tflabkv[a-z0-9]{4}$", output.key_vault_name))
    error_message = "Key Vault name must be <prefix>kv<4 random chars> so rebuilds never collide with soft-deleted vaults."
  }
}

run "rejects_prefix_with_tfe" {
  command = plan
  variables { prefix = "mytfe" }
  expect_failures = [var.prefix]
}

run "rejects_uppercase_prefix" {
  command = plan
  variables { prefix = "Lab1" }
  expect_failures = [var.prefix]
}

run "rejects_short_prefix" {
  command = plan
  variables { prefix = "ab" }
  expect_failures = [var.prefix]
}

run "rejects_bad_operator_cidr" {
  command = plan
  variables { operator_cidrs = ["203.0.113.10"] }
  expect_failures = [var.operator_cidrs]
}

run "key_vault_acl_contents" {
  command = apply

  assert {
    condition     = toset(azurerm_key_vault.this.network_acls[0].ip_rules) == toset(["203.0.113.10/32"])
    error_message = "Key Vault ip_rules must equal the operator CIDRs."
  }
  assert {
    condition = (
      contains(tolist(azurerm_key_vault.this.network_acls[0].virtual_network_subnet_ids), azurerm_subnet.aks.id) &&
      contains(tolist(azurerm_key_vault.this.network_acls[0].virtual_network_subnet_ids), azurerm_subnet.agent.id)
    )
    error_message = "Key Vault must allow the AKS and agent subnets."
  }
  assert {
    condition     = azurerm_key_vault.this.network_acls[0].default_action == "Deny"
    error_message = "Key Vault default action must be Deny."
  }
}
