# Optional demo access: a point-to-site VPN into the lab VNet plus an Azure DNS Private Resolver,
# so a laptop can resolve the private zone and open the internal TFE URL in a normal browser.
# Mirrors a customer path: corporate network -> hub -> private resolver. Off by default.
# Profile for the laptop: scripts/demo-vpn-profile.sh. See docs/runbook.md.

locals {
  demo_vpn_count = var.enable_demo_vpn ? 1 : 0
  # module.network exposes the VNet ID but not its name; the name is the last ID segment.
  vnet_name = element(split("/", module.network.vnet_id), length(split("/", module.network.vnet_id)) - 1)
}

resource "azurerm_subnet" "demo_vpn_gateway" {
  count                = local.demo_vpn_count
  name                 = "GatewaySubnet" # Azure requires this exact name.
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.demo_vpn_gateway_subnet_cidr]
}

resource "azurerm_subnet" "demo_vpn_resolver" {
  count                = local.demo_vpn_count
  name                 = "${var.prefix}-dns-inbound"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.demo_vpn_resolver_subnet_cidr]

  delegation {
    name = "dns-resolver"
    service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Certificates. Short-lived, lab only. Private keys land in local state like the other bootstrap secrets.
resource "tls_private_key" "demo_vpn_ca" {
  count     = local.demo_vpn_count
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "demo_vpn_ca" {
  count                 = local.demo_vpn_count
  private_key_pem       = tls_private_key.demo_vpn_ca[0].private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.demo_vpn_cert_validity_hours
  allowed_uses          = ["cert_signing", "crl_signing", "digital_signature"]

  subject {
    common_name = "${var.prefix}-demo-vpn-root"
  }
}

resource "tls_private_key" "demo_vpn_client" {
  count     = local.demo_vpn_count
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "demo_vpn_client" {
  count           = local.demo_vpn_count
  private_key_pem = tls_private_key.demo_vpn_client[0].private_key_pem

  subject {
    common_name = "${var.prefix}-demo-client"
  }
}

resource "tls_locally_signed_cert" "demo_vpn_client" {
  count                 = local.demo_vpn_count
  cert_request_pem      = tls_cert_request.demo_vpn_client[0].cert_request_pem
  ca_private_key_pem    = tls_private_key.demo_vpn_ca[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.demo_vpn_ca[0].cert_pem
  validity_period_hours = var.demo_vpn_cert_validity_hours
  allowed_uses          = ["client_auth", "digital_signature", "key_encipherment"]
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_public_ip" "demo_vpn" {
  count               = local.demo_vpn_count
  name                = "${var.prefix}-demo-vpn-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.tags
}

# The gateway takes 30 to 45 minutes to create.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_virtual_network_gateway" "demo_vpn" {
  count               = local.demo_vpn_count
  name                = "${var.prefix}-demo-vpn-gw"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.demo_vpn_gateway_sku
  generation          = "Generation1"
  active_active       = false
  bgp_enabled         = false
  tags                = local.tags

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = azurerm_public_ip.demo_vpn[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.demo_vpn_gateway[0].id
  }

  vpn_client_configuration {
    address_space        = [var.demo_vpn_client_address_pool]
    vpn_client_protocols = ["OpenVPN"]
    vpn_auth_types       = ["Certificate"]

    root_certificate {
      name = "${var.prefix}-demo-root"
      # Azure wants the base64 body only: no BEGIN/END lines, no newlines.
      public_cert_data = replace(replace(tls_self_signed_cert.demo_vpn_ca[0].cert_pem, "/-----(BEGIN|END) CERTIFICATE-----/", ""), "/\\s+/", "")
    }
  }
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_private_dns_resolver" "demo_vpn" {
  count               = local.demo_vpn_count
  name                = "${var.prefix}-demo-resolver"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_id  = module.network.vnet_id
  tags                = local.tags

  # The VNet stays "Updating" while the gateway is created (20+ minutes), and Azure rejects a resolver
  # on a VNet that isn't "Succeeded" ("Virtual network in NRP is not in the succeeded provisioning state").
  depends_on = [azurerm_virtual_network_gateway.demo_vpn]
}

# The private zone is linked to this VNet, so the inbound endpoint answers the TFE hostname with the internal LB IP.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_private_dns_resolver_inbound_endpoint" "demo_vpn" {
  count                   = local.demo_vpn_count
  name                    = "${var.prefix}-demo-inbound"
  location                = var.location
  private_dns_resolver_id = azurerm_private_dns_resolver.demo_vpn[0].id
  tags                    = local.tags

  ip_configurations {
    private_ip_allocation_method = "Static"
    private_ip_address           = cidrhost(var.demo_vpn_resolver_subnet_cidr, 4)
    subnet_id                    = azurerm_subnet.demo_vpn_resolver[0].id
  }
}
