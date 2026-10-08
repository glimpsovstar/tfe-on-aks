mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
      object_id = "11111111-1111-1111-1111-111111111111"
    }
  }
  mock_data "azurerm_dns_zone" {
    defaults = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dns-rg/providers/Microsoft.Network/dnsZones/example.com" }
  }
  mock_resource "azurerm_dns_zone" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/dnsZones/tfelab.example.com"
      name_servers = ["ns1-01.azure-dns.com.", "ns2-01.azure-dns.net."]
    }
  }
  # Mocked IDs must be well-formed Azure resource IDs: the provider validates them in dependent resources.
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tflab-stack-id"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/publicIPAddresses/tflab-agent-pip"
      ip_address = "198.51.100.7"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/networkInterfaces/tflab-agent-nic"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/networkSecurityGroups/tflab-agent-nsg"
    }
  }
  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Compute/virtualMachines/tflab-agent"
    }
  }
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
  mock_resource "azurerm_virtual_network_gateway" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/virtualNetworkGateways/tflab-demo-vpn-gw"
    }
  }
  mock_resource "azurerm_private_dns_resolver" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/dnsResolvers/tflab-demo-resolver"
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.KeyVault/vaults/tflabkvmock"
    }
  }
}
mock_provider "azurerm" {
  alias = "parent_dns"
}
mock_provider "tfe" {
  mock_data "tfe_organization" {
    defaults = { name = "example-org" }
  }
  # The tfe provider validates ID formats on dependent resources.
  mock_resource "tfe_variable_set" {
    defaults = { id = "varset-aBcDeFgHiJkLmNoP" }
  }
  mock_resource "tfe_project" {
    defaults = { id = "prj-aBcDeFgHiJkLmNoP" }
  }
  mock_resource "tfe_agent_pool" {
    defaults = { id = "apool-aBcDeFgHiJkLmNoP" }
  }
}
mock_provider "random" {
  mock_resource "random_string" {
    defaults = {
      result = "ab12"
    }
  }
}
mock_provider "time" {}
mock_provider "tls" {
  # Shaped like real PEMs so the BEGIN/END stripping can be asserted.
  mock_resource "tls_self_signed_cert" {
    defaults = {
      cert_pem = "-----BEGIN CERTIFICATE-----\nMIIBmockrootcertbody\nAAAA\n-----END CERTIFICATE-----\n"
    }
  }
  mock_resource "tls_locally_signed_cert" {
    defaults = {
      cert_pem = "-----BEGIN CERTIFICATE-----\nMIIBmockclientcertbody\nBBBB\n-----END CERTIFICATE-----\n"
    }
  }
  # The azurerm provider validates the SSH key format.
  mock_resource "tls_private_key" {
    defaults = {
      public_key_openssh = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILbMB/OXupxJpu3Mk/33KWZvc4AFTX4OAdFNn5G0VzpO\n"
    }
  }
}

variables {
  prefix                         = "tflab"
  subscription_id                = "00000000-0000-0000-0000-000000000000"
  operator_cidrs                 = ["203.0.113.10/32"]
  public_dns_zone_name           = "example.com"
  public_dns_zone_resource_group = "dns-rg"
  hcp_organization               = "example-org"
  hcp_project                    = "tfe-on-aks"
  stack_name                     = "tfe-aks"
  github_repo                    = "your-org/tfe-on-aks"
  github_app_installation_id     = "ghain-test"
  tfe_license_file               = "tests/fixtures/fake.hclic"
  owner_tag                      = "platform-team"
  expires_tag                    = "2026-10-20"
  budget_contact_emails          = ["owner@example.com"]
  tfc_agent_version              = "1.28.0"
}

run "federated_credentials_match_stack_subjects" {
  command = apply

  assert {
    condition = (
      azurerm_federated_identity_credential.stack["plan"].subject == "organization:example-org:project:tfe-on-aks:stack:tfe-aks:deployment:main:operation:plan" &&
      azurerm_federated_identity_credential.stack["apply"].subject == "organization:example-org:project:tfe-on-aks:stack:tfe-aks:deployment:main:operation:apply"
    )
    error_message = "Federated credential subjects must match the Stack deployment."
  }
  assert {
    condition     = azurerm_federated_identity_credential.stack["plan"].issuer == "https://app.terraform.io" && contains(azurerm_federated_identity_credential.stack["plan"].audience, "api://AzureADTokenExchange")
    error_message = "Issuer and audience must be HCP Terraform's."
  }
}

run "lab_budget_alerts" {
  command = apply

  assert {
    condition     = azurerm_consumption_budget_resource_group.lab.amount == 500 && length(azurerm_consumption_budget_resource_group.lab.notification) == 2
    error_message = "Lab resource group needs a monthly budget with 50% and 90% alerts."
  }
}

run "stack_identity_roles" {
  command = apply

  assert {
    condition     = azurerm_role_assignment.stack_contributor.role_definition_name == "Contributor" && azurerm_role_assignment.stack_rbac_admin.role_definition_name == "Role Based Access Control Administrator"
    error_message = "Stack identity gets Contributor plus Role Based Access Control Administrator (never User Access Administrator)."
  }
  assert {
    condition     = azurerm_role_assignment.stack_rbac_admin.condition_version == "2.0" && strcontains(azurerm_role_assignment.stack_rbac_admin.condition, "4d97b98b-1d4f-4787-a291-c67834d212e7") && strcontains(azurerm_role_assignment.stack_rbac_admin.condition, "b7e6dc6d-f1e8-4753-8033-0f276bb0955b") && length(regexall("[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", azurerm_role_assignment.stack_rbac_admin.condition)) == 4
    error_message = "The ABAC condition must limit assignable roles to Network Contributor and Storage Blob Data Owner only (write and delete)."
  }
}

run "agent_pool_scoped_to_project" {
  command = apply

  assert {
    condition     = tfe_agent_pool.this.organization_scoped == false
    error_message = "Agent pool must not be organization-wide."
  }
  assert {
    condition     = contains(tolist(tfe_agent_pool_allowed_projects.this.allowed_project_ids), tfe_project.this.id)
    error_message = "Agent pool must be allowed for the project."
  }
}

run "varset_has_every_stack_input" {
  command = apply

  assert {
    condition = toset(keys(tfe_variable.lab)) == toset([
      "subscription_id", "tenant_id", "client_id", "resource_group_name", "location", "prefix",
      "vnet_id", "lb_subnet_id", "lb_subnet_name", "aks_subnet_id", "db_subnet_id", "redis_subnet_id",
      "key_vault_id", "db_password_secret_name", "private_dns_zone_name", "public_dns_zone_name",
      "public_dns_zone_resource_group", "tfe_hostname", "lb_static_ip", "aks_authorized_cidrs_csv",
      "owner_tag", "expires_tag",
    ])
    error_message = "Variable set must carry every non-secret Stack input."
  }
  assert {
    condition     = tfe_variable.license.sensitive && tfe_variable.license.key == "tfe_license"
    error_message = "Licence must be a sensitive variable named tfe_license."
  }
  assert {
    condition     = tfe_variable_set.lab.name == "tfe-aks-inputs" && tfe_variable_set.lab.global == false
    error_message = "Variable set must have the fixed name and be project-scoped."
  }
}

run "stack_created_on_agent_pool" {
  command = apply

  assert {
    condition     = tfe_stack.this[0].agent_pool_id == tfe_agent_pool.this.id && tfe_stack.this[0].vcs_repo.identifier == "your-org/tfe-on-aks"
    error_message = "Stack must use the agent pool and the GitHub repo."
  }
}

run "stack_creation_optional" {
  command = apply
  variables { create_stack = false }

  assert {
    condition     = length(tfe_stack.this) == 0 && length(tfe_stack.oauth) == 0
    error_message = "create_stack = false must skip the Stack."
  }
}

run "agent_vm_shape" {
  command = apply

  assert {
    condition     = azurerm_linux_virtual_machine.agent.size == "Standard_B2ls_v2"
    error_message = "Agent VM size must default to Standard_B2ls_v2."
  }
  assert {
    condition     = azurerm_linux_virtual_machine.agent.identity[0].type == "SystemAssigned"
    error_message = "Agent VM needs a system-assigned identity for the ACME DNS challenge."
  }
  assert {
    condition     = azurerm_public_ip.agent.sku == "Standard" && azurerm_public_ip.agent.allocation_method == "Static"
    error_message = "Agent egress IP must be a Standard static IP."
  }
}

run "agent_cloud_init_runs_tfc_agent" {
  command = apply

  assert {
    condition     = strcontains(base64decode(azurerm_linux_virtual_machine.agent.custom_data), "tfc-agent_1.28.0_linux_amd64.zip")
    error_message = "cloud-init must install the pinned tfc-agent version."
  }
  assert {
    condition     = strcontains(base64decode(azurerm_linux_virtual_machine.agent.custom_data), "TFC_AGENT_TOKEN=")
    error_message = "cloud-init must pass the agent token."
  }
}

run "agent_has_dns_zone_role" {
  command = apply

  assert {
    condition     = azurerm_role_assignment.agent_dns.role_definition_name == "DNS Zone Contributor"
    error_message = "Agent identity needs DNS Zone Contributor on the public zone."
  }
  assert {
    condition     = azurerm_role_assignment.agent_dns.scope == azurerm_dns_zone.lab.id
    error_message = "DNS Zone Contributor must be scoped to the delegated lab child zone only."
  }
}

run "agent_no_inbound_by_default" {
  command = apply

  assert {
    condition     = length(azurerm_network_security_rule.agent_ssh) == 0
    error_message = "No inbound rule unless enable_agent_ssh = true."
  }
}

run "lab_child_zone_delegated" {
  command = apply

  assert {
    condition     = azurerm_dns_zone.lab.name == "tfelab.example.com"
    error_message = "Child zone must be <lab_subdomain>.<public_dns_zone_name>."
  }
  assert {
    condition     = azurerm_dns_ns_record.lab_delegation[0].name == "tfelab" && azurerm_dns_ns_record.lab_delegation[0].zone_name == "example.com"
    error_message = "NS delegation must be created in the parent zone under the lab subdomain label."
  }
  assert {
    condition     = azurerm_dns_ns_record.lab_delegation[0].resource_group_name == "dns-rg"
    error_message = "NS delegation must be written to the parent zone's resource group."
  }
}

run "varset_points_acme_at_child_zone" {
  command = apply

  assert {
    condition     = tfe_variable.lab["public_dns_zone_name"].value == "tfelab.example.com"
    error_message = "ACME challenge zone name must be the child zone."
  }
  assert {
    condition     = tfe_variable.lab["public_dns_zone_resource_group"].value == "tflab-tfe-rg"
    error_message = "ACME challenge zone resource group must be the lab RG."
  }
}

run "delegation_targets_parent_zone_in_other_subscription" {
  command = apply
  variables { public_dns_zone_subscription_id = "99999999-9999-9999-9999-999999999999" }

  assert {
    condition     = azurerm_dns_ns_record.lab_delegation[0].zone_name == "example.com" && azurerm_dns_ns_record.lab_delegation[0].resource_group_name == "dns-rg"
    error_message = "NS delegation must still target the parent zone and resource group when the zone is in another subscription."
  }
}

run "delegation_can_be_skipped" {
  command = apply
  variables { create_lab_delegation = false }

  assert {
    condition     = length(azurerm_dns_ns_record.lab_delegation) == 0
    error_message = "create_lab_delegation = false must skip the NS record."
  }
  assert {
    condition     = length(output.lab_dns_zone_name_servers) > 0
    error_message = "Child zone name servers must be exposed for manual delegation."
  }
}

run "operator_outputs" {
  command = apply

  assert {
    condition     = output.aks_cluster_name == "tflab-tfe-aks"
    error_message = "aks_cluster_name must follow the HVD pattern <prefix>-tfe-aks."
  }
  assert {
    condition     = output.key_vault_name == module.network.key_vault_name
    error_message = "key_vault_name must come from the network module."
  }
}

run "stack_via_oauth_token" {
  command = apply
  variables {
    github_app_installation_id = null
    vcs_oauth_token_id         = "ot-test"
  }

  assert {
    condition     = tfe_stack.oauth[0].vcs_repo.oauth_token_id == "ot-test" && length(tfe_stack.this) == 0
    error_message = "Stack must use the VCS OAuth token when it is set."
  }
}

run "stack_vcs_both_set_rejected" {
  command = plan
  variables { vcs_oauth_token_id = "ot-test" }

  expect_failures = [var.vcs_oauth_token_id]
}

run "stack_vcs_neither_set_rejected" {
  command = plan
  variables { github_app_installation_id = null }

  expect_failures = [var.vcs_oauth_token_id]
}

run "stack_vcs_not_required_without_stack" {
  command = plan
  variables {
    create_stack               = false
    github_app_installation_id = null
  }
}

run "demo_vpn_off_by_default" {
  command = apply

  assert {
    condition = (
      length(azurerm_subnet.demo_vpn_gateway) == 0 &&
      length(azurerm_subnet.demo_vpn_resolver) == 0 &&
      length(azurerm_public_ip.demo_vpn) == 0 &&
      length(azurerm_virtual_network_gateway.demo_vpn) == 0 &&
      length(azurerm_private_dns_resolver.demo_vpn) == 0 &&
      length(azurerm_private_dns_resolver_inbound_endpoint.demo_vpn) == 0 &&
      length(tls_private_key.demo_vpn_ca) == 0 &&
      length(tls_self_signed_cert.demo_vpn_ca) == 0 &&
      length(tls_private_key.demo_vpn_client) == 0 &&
      length(tls_cert_request.demo_vpn_client) == 0 &&
      length(tls_locally_signed_cert.demo_vpn_client) == 0
    )
    error_message = "enable_demo_vpn = false must create none of the demo VPN, resolver or certificate resources."
  }
  assert {
    condition = (
      output.demo_vpn_gateway_name == null &&
      output.demo_vpn_dns_server_ip == null &&
      output.demo_vpn_client_cert_pem == null &&
      output.demo_vpn_client_key_pem == null &&
      output.demo_vpn_root_cert_pem == null
    )
    error_message = "Demo VPN outputs must be null when disabled."
  }
}

run "demo_vpn_gateway" {
  command = apply
  variables { enable_demo_vpn = true }

  # The provider checks the subnet ID ends in /subnets/GatewaySubnet; the shared mock ID does not.
  override_resource {
    target = azurerm_subnet.demo_vpn_gateway[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.Network/virtualNetworks/tflab-vnet/subnets/GatewaySubnet"
    }
  }

  assert {
    condition     = azurerm_virtual_network_gateway.demo_vpn[0].sku == "VpnGw1AZ" && azurerm_virtual_network_gateway.demo_vpn[0].type == "Vpn" && azurerm_virtual_network_gateway.demo_vpn[0].vpn_type == "RouteBased"
    error_message = "Gateway must be a route-based VpnGw1AZ."
  }
  assert {
    condition     = azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].vpn_client_protocols == toset(["OpenVPN"]) && azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].vpn_auth_types == toset(["Certificate"])
    error_message = "Gateway must offer OpenVPN with certificate auth only."
  }
  assert {
    condition     = azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].address_space == tolist(["172.16.201.0/24"])
    error_message = "Client address pool must default to 172.16.201.0/24."
  }
  assert {
    condition     = length(azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].root_certificate) == 1
    error_message = "Gateway needs exactly one root certificate."
  }
  assert {
    condition     = !strcontains([for r in azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].root_certificate : r.public_cert_data][0], "BEGIN") && !strcontains([for r in azurerm_virtual_network_gateway.demo_vpn[0].vpn_client_configuration[0].root_certificate : r.public_cert_data][0], "\n")
    error_message = "root_certificate data must be the bare base64 body (no BEGIN/END lines, no newlines)."
  }
  assert {
    condition     = azurerm_public_ip.demo_vpn[0].sku == "Standard" && azurerm_public_ip.demo_vpn[0].allocation_method == "Static" && length(azurerm_public_ip.demo_vpn[0].zones) == 3
    error_message = "Gateway public IP must be Standard, static and zone redundant."
  }
}

run "demo_vpn_subnets" {
  command = apply
  variables { enable_demo_vpn = true }

  assert {
    condition     = azurerm_subnet.demo_vpn_gateway[0].name == "GatewaySubnet" && azurerm_subnet.demo_vpn_gateway[0].address_prefixes == tolist(["10.40.255.0/27"])
    error_message = "Gateway subnet must be named exactly GatewaySubnet and use 10.40.255.0/27."
  }
  assert {
    condition     = azurerm_subnet.demo_vpn_resolver[0].name == "tflab-dns-inbound" && azurerm_subnet.demo_vpn_resolver[0].address_prefixes == tolist(["10.40.254.0/28"])
    error_message = "Resolver subnet must be <prefix>-dns-inbound on 10.40.254.0/28."
  }
  assert {
    condition     = one(azurerm_subnet.demo_vpn_resolver[0].delegation).service_delegation[0].name == "Microsoft.Network/dnsResolvers"
    error_message = "Resolver subnet must be delegated to Microsoft.Network/dnsResolvers."
  }
}

run "demo_vpn_resolver" {
  command = apply
  variables { enable_demo_vpn = true }

  assert {
    condition     = azurerm_private_dns_resolver_inbound_endpoint.demo_vpn[0].ip_configurations[0].private_ip_address == "10.40.254.4" && azurerm_private_dns_resolver_inbound_endpoint.demo_vpn[0].ip_configurations[0].private_ip_allocation_method == "Static"
    error_message = "Inbound endpoint must use the static IP 10.40.254.4."
  }
  assert {
    condition     = output.demo_vpn_dns_server_ip == "10.40.254.4" && output.demo_vpn_gateway_name == "tflab-demo-vpn-gw"
    error_message = "Outputs must expose the DNS server IP and gateway name."
  }
}

run "demo_vpn_client_cert" {
  command = apply
  variables { enable_demo_vpn = true }

  assert {
    condition     = tls_self_signed_cert.demo_vpn_ca[0].is_ca_certificate && tls_self_signed_cert.demo_vpn_ca[0].validity_period_hours == 720
    error_message = "Root CA must be a CA certificate valid for 720 hours by default."
  }
  assert {
    condition     = tls_cert_request.demo_vpn_client[0].subject[0].common_name == "tflab-demo-client" && contains(tls_locally_signed_cert.demo_vpn_client[0].allowed_uses, "client_auth")
    error_message = "Client certificate must be CN <prefix>-demo-client with client_auth."
  }
  assert {
    condition     = output.demo_vpn_client_cert_pem != null && output.demo_vpn_root_cert_pem != null
    error_message = "Certificates must be exposed when enabled."
  }
}
