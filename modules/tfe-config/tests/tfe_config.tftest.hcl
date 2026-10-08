mock_provider "tfe" {
  mock_data "tfe_team" {
    defaults = { id = "team-owners" }
  }
}

variables {
  organization_name           = "example-org"
  organization_email          = "platform@example.com"
  projects                    = ["sandbox"]
  owners_member_emails        = ["lead@example.com"]
  platform_team_member_emails = ["eng1@example.com", "eng2@example.com"]
}

run "org_and_projects" {
  command = apply

  assert {
    condition     = tfe_organization.this.name == "example-org" && tfe_organization.this.cost_estimation_enabled == false
    error_message = "Org exists with cost estimation off (no prices.azure.com egress)."
  }
  assert {
    condition     = toset(keys(output.project_ids)) == toset(["platform", "sandbox"])
    error_message = "platform project plus listed projects."
  }
}

run "platform_team_admin_on_platform_project" {
  command = apply

  assert {
    condition     = tfe_team_project_access.platform.access == "admin" && tfe_team_project_access.platform.team_id == tfe_team.platform.id
    error_message = "platform team gets admin on the platform project."
  }
  assert {
    condition     = length(tfe_team_organization_member.platform) == 2
    error_message = "Each platform engineer is a member."
  }
}

run "owners_membership_is_additive" {
  command = apply

  assert {
    condition     = length(tfe_team_organization_member.owners) == 1 && tfe_team_organization_member.owners["lead@example.com"].team_id == "team-owners"
    error_message = "Owners members are added one by one (never authoritative, so the admin keeps access)."
  }
}

run "rejects_bad_org_name" {
  command = plan
  variables { organization_name = "ASC Lab" }
  expect_failures = [var.organization_name]
}

run "org_auth_policy_default_is_two_factor" {
  command = apply

  assert {
    condition     = tfe_organization.this.collaborator_auth_policy == "two_factor_mandatory"
    error_message = "Default must be two_factor_mandatory (secure by default); see README Security."
  }
}

run "org_auth_policy_password_opt_in_passes_through" {
  command = apply
  variables { collaborator_auth_policy = "password" }

  assert {
    condition     = tfe_organization.this.collaborator_auth_policy == "password"
    error_message = "An explicit password opt-in must pass through to the organization."
  }
}

run "rejects_bad_auth_policy" {
  command = plan
  variables { collaborator_auth_policy = "none" }
  expect_failures = [var.collaborator_auth_policy]
}

run "same_email_in_both_lists_is_deduped" {
  command = apply
  variables {
    owners_member_emails        = ["a@x.com"]
    platform_team_member_emails = ["a@x.com", "b@x.com"]
  }

  assert {
    condition     = length(tfe_organization_membership.this) == 2
    error_message = "One membership per unique email."
  }
}

run "platform_in_projects_is_deduped" {
  command = apply
  variables { projects = ["platform", "sandbox"] }

  assert {
    condition     = toset(keys(tfe_project.this)) == toset(["platform", "sandbox"])
    error_message = "platform listed explicitly must not duplicate."
  }
}
