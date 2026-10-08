resource "tls_private_key" "agent" {
  algorithm = "ED25519"
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_public_ip" "agent" {
  name                = "${var.prefix}-agent-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.tags
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_network_security_group" "agent" {
  name                = "${var.prefix}-agent-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "agent_ssh" {
  count                       = var.enable_agent_ssh ? 1 : 0
  name                        = "ssh-from-operator"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.operator_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.agent.name
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_network_interface" "agent" {
  name                = "${var.prefix}-agent-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = module.network.agent_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent.id
  }
}

resource "azurerm_network_interface_security_group_association" "agent" {
  network_interface_id      = azurerm_network_interface.agent.id
  network_security_group_id = azurerm_network_security_group.agent.id
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_linux_virtual_machine" "agent" {
  name                  = "${var.prefix}-agent"
  location              = var.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.agent_vm_size
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.agent.id]
  tags                  = local.tags

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.agent.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    agent_token   = tfe_agent_token.this.token
    agent_name    = "${var.prefix}-agent"
    agent_version = var.tfc_agent_version
  }))
}

# Delegated public child zone: the agent identity (reachable from every run on the agent via IMDS)
# gets DNS write access to this zone only, never to the parent zone.
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_dns_zone" "lab" {
  name                = "${var.lab_subdomain}.${var.public_dns_zone_name}"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# Written with the operator's credentials during bootstrap apply, using the provider alias that
# points at the parent zone's subscription. Set create_lab_delegation = false when the parent zone
# is in another tenant and add the NS record by hand (see lab_dns_zone_name_servers).
resource "azurerm_dns_ns_record" "lab_delegation" {
  count               = var.create_lab_delegation ? 1 : 0
  provider            = azurerm.parent_dns
  name                = var.lab_subdomain
  zone_name           = var.public_dns_zone_name
  resource_group_name = var.public_dns_zone_resource_group
  ttl                 = 300
  records             = azurerm_dns_zone.lab.name_servers
}

resource "azurerm_role_assignment" "agent_dns" {
  scope                = azurerm_dns_zone.lab.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_linux_virtual_machine.agent.identity[0].principal_id
}
