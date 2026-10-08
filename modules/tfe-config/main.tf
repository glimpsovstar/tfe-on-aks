resource "tfe_organization" "this" {
  name                    = var.organization_name
  email                   = var.organization_email
  cost_estimation_enabled = false
  # Explicit on purpose: the provider default is also "password"; see README Security.
  collaborator_auth_policy = var.collaborator_auth_policy
}

resource "tfe_project" "this" {
  for_each     = toset(concat(["platform"], var.projects))
  name         = each.key
  organization = tfe_organization.this.name
}

# TFE creates the owners team with the organization; it cannot be created with tfe_team.
data "tfe_team" "owners" {
  name         = "owners"
  organization = tfe_organization.this.name
}

resource "tfe_organization_membership" "this" {
  for_each     = toset(concat(var.owners_member_emails, var.platform_team_member_emails))
  organization = tfe_organization.this.name
  email        = each.key
}

resource "tfe_team_organization_member" "owners" {
  for_each                   = toset(var.owners_member_emails)
  team_id                    = data.tfe_team.owners.id
  organization_membership_id = tfe_organization_membership.this[each.key].id
}

resource "tfe_team" "platform" {
  name         = "platform"
  organization = tfe_organization.this.name
  visibility   = "organization"
}

resource "tfe_team_organization_member" "platform" {
  for_each                   = toset(var.platform_team_member_emails)
  team_id                    = tfe_team.platform.id
  organization_membership_id = tfe_organization_membership.this[each.key].id
}

resource "tfe_team_project_access" "platform" {
  access     = "admin"
  team_id    = tfe_team.platform.id
  project_id = tfe_project.this["platform"].id
}
