output "tfe_hostname" {
  value       = var.tfe_hostname
  description = "TFE hostname (for the tfe provider)."
}
output "tfe_url" {
  value       = "https://${var.tfe_hostname}"
  description = "TFE URL."
}
output "iact_token" {
  value       = random_password.iact.result
  sensitive   = true
  description = "Preset initial admin creation token."
}
output "helm_values_yaml" {
  value       = yamlencode(local.helm_values)
  description = "Rendered Helm values (no secrets)."
}
