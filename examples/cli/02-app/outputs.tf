output "tfe_hostname" {
  description = "TFE FQDN."
  value       = module.tfe_install.tfe_hostname
}

output "tfe_url" {
  description = "TFE URL."
  value       = "https://${module.tfe_install.tfe_hostname}"
}
