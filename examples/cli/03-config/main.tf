module "tfe_config" {
  source = "../../../modules/tfe-config"

  organization_name        = var.organization_name
  organization_email       = var.organization_email
  collaborator_auth_policy = var.collaborator_auth_policy
}
