output "organization_name" {
  value       = tfe_organization.this.name
  description = "Organization name."
}
output "project_ids" {
  value       = { for k, p in tfe_project.this : k => p.id }
  description = "Project IDs by name."
}
output "platform_team_id" {
  value       = tfe_team.platform.id
  description = "platform team ID."
}
