output "tfe_url" {
  type        = string
  value       = component.tfe_install.tfe_url
  description = "TFE URL (resolves inside the VNet)."
}

output "organization_name" {
  type        = string
  value       = var.configure_tfe ? component.tfe_config["this"].organization_name : ""
  description = "TFE organization created by the Stack."
}
