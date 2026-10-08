output "organization_name" {
  description = "TFE organization name."
  value       = module.tfe_config.organization_name
}

output "project_ids" {
  description = "Project IDs by name."
  value       = module.tfe_config.project_ids
}

output "platform_team_id" {
  description = "ID of the platform team."
  value       = module.tfe_config.platform_team_id
}
