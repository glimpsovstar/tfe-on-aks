output "tfe_hostname" {
  value       = local.tfe_hostname
  description = "TFE FQDN: tfe.<lab_subdomain>.<public_dns_zone_name>."
}

output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "Virtual network ID."
}

output "lb_subnet_id" {
  value       = azurerm_subnet.lb.id
  description = "Load balancer subnet ID."
}

output "lb_subnet_name" {
  value       = azurerm_subnet.lb.name
  description = "Load balancer subnet name."
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks.id
  description = "AKS subnet ID."
}

output "db_subnet_id" {
  value       = azurerm_subnet.db.id
  description = "PostgreSQL delegated subnet ID."
}

output "redis_subnet_id" {
  value       = azurerm_subnet.redis.id
  description = "Redis private endpoint subnet ID."
}

output "agent_subnet_id" {
  value       = azurerm_subnet.agent.id
  description = "Agent subnet ID."
}

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Key Vault ID."
}

output "key_vault_name" {
  value       = azurerm_key_vault.this.name
  description = "Key Vault name (prefix, kv, 4 random chars)."
}

output "db_password_secret_name" {
  value       = azurerm_key_vault_secret.db_password.name
  description = "Key Vault secret name holding the TFE database password."
}

output "private_dns_zone_name" {
  value       = azurerm_private_dns_zone.tfe.name
  description = "Private DNS zone name covering the lab subdomain."
}

output "lb_static_ip" {
  value       = cidrhost(var.subnet_cidrs.lb, 10)
  description = "Static private IP for the TFE internal load balancer."
}
