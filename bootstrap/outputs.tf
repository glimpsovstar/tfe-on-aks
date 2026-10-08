output "stack_client_id" {
  value       = azurerm_user_assigned_identity.stack.client_id
  description = "Client ID the Stack uses for Azure OIDC."
}
output "tfe_hostname" {
  value       = module.network.tfe_hostname
  description = "TFE FQDN (resolves only inside the VNet)."
}
output "agent_public_ip" {
  value       = azurerm_public_ip.agent.ip_address
  description = "Agent VM outbound IP (allowed on the AKS API and storage)."
}
output "varset_name" {
  value       = tfe_variable_set.lab.name
  description = "Variable set the Stack reads with a store block."
}
output "agent_ssh_private_key" {
  value       = tls_private_key.agent.private_key_openssh
  sensitive   = true
  description = "SSH key for the agent VM (only useful with enable_agent_ssh = true)."
}
output "lab_dns_zone_name_servers" {
  value       = azurerm_dns_zone.lab.name_servers
  description = "Name servers of the delegated lab child zone. Add them as an NS record in the parent zone by hand when create_lab_delegation = false."
}
output "key_vault_name" {
  value       = module.network.key_vault_name
  description = "Key Vault name (holds the TFE secrets and the admin token)."
}
output "aks_cluster_name" {
  value       = "${var.prefix}-tfe-aks"
  description = "AKS cluster name. The HVD module 0.3.0 names it <friendly_name_prefix>-tfe-aks and the Stack passes prefix as friendly_name_prefix."
}
output "demo_vpn_gateway_name" {
  value       = one(azurerm_virtual_network_gateway.demo_vpn[*].name)
  description = "Demo VPN gateway name. Null unless enable_demo_vpn = true."
}
output "demo_vpn_dns_server_ip" {
  value       = one(azurerm_private_dns_resolver_inbound_endpoint.demo_vpn[*].ip_configurations[0].private_ip_address)
  description = "DNS Private Resolver inbound endpoint IP; the VPN client uses it as its DNS server. Null unless enable_demo_vpn = true."
}
output "demo_vpn_client_cert_pem" {
  value       = one(tls_locally_signed_cert.demo_vpn_client[*].cert_pem)
  sensitive   = true
  description = "Client certificate (PEM) for the VPN. Null unless enable_demo_vpn = true."
}
output "demo_vpn_client_key_pem" {
  value       = one(tls_private_key.demo_vpn_client[*].private_key_pem)
  sensitive   = true
  description = "Client private key (PEM) for the VPN. Null unless enable_demo_vpn = true."
}
output "demo_vpn_root_cert_pem" {
  value       = one(tls_self_signed_cert.demo_vpn_ca[*].cert_pem)
  description = "Root CA certificate (PEM) the gateway trusts. Null unless enable_demo_vpn = true."
}
