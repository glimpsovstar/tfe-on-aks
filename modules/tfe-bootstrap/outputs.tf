output "admin_token" {
  value       = local.admin_token
  sensitive   = true
  description = "API token of the first site admin."
}
output "admin_username" {
  value       = var.admin_username
  description = "First site admin username."
}
