data "tfe_organization" "this" {
  name = var.hcp_organization
}

resource "tfe_project" "this" {
  name         = var.hcp_project
  organization = data.tfe_organization.this.name
}

resource "tfe_agent_pool" "this" {
  name                = "${var.prefix}-tfe-aks"
  organization        = data.tfe_organization.this.name
  organization_scoped = false
}

resource "tfe_agent_pool_allowed_projects" "this" {
  agent_pool_id       = tfe_agent_pool.this.id
  allowed_project_ids = [tfe_project.this.id]
}

resource "tfe_agent_token" "this" {
  agent_pool_id = tfe_agent_pool.this.id
  description   = "${var.prefix} agent VM"
}

resource "tfe_variable_set" "lab" {
  name              = var.varset_name
  description       = "Inputs for the ${var.stack_name} Stack, written by bootstrap/."
  organization      = data.tfe_organization.this.name
  global            = false
  parent_project_id = tfe_project.this.id
}

resource "tfe_project_variable_set" "lab" {
  project_id      = tfe_project.this.id
  variable_set_id = tfe_variable_set.lab.id
}

locals {
  agent_ip = azurerm_public_ip.agent.ip_address
  stack_inputs = {
    subscription_id                = var.subscription_id
    tenant_id                      = data.azurerm_client_config.current.tenant_id
    client_id                      = azurerm_user_assigned_identity.stack.client_id
    resource_group_name            = azurerm_resource_group.this.name
    location                       = var.location
    prefix                         = var.prefix
    vnet_id                        = module.network.vnet_id
    lb_subnet_id                   = module.network.lb_subnet_id
    lb_subnet_name                 = module.network.lb_subnet_name
    aks_subnet_id                  = module.network.aks_subnet_id
    db_subnet_id                   = module.network.db_subnet_id
    redis_subnet_id                = module.network.redis_subnet_id
    key_vault_id                   = module.network.key_vault_id
    db_password_secret_name        = module.network.db_password_secret_name
    private_dns_zone_name          = module.network.private_dns_zone_name
    public_dns_zone_name           = azurerm_dns_zone.lab.name
    public_dns_zone_resource_group = azurerm_resource_group.this.name
    tfe_hostname                   = module.network.tfe_hostname
    lb_static_ip                   = module.network.lb_static_ip
    aks_authorized_cidrs_csv       = join(",", concat(["${local.agent_ip}/32"], var.operator_cidrs))
    owner_tag                      = var.owner_tag
    expires_tag                    = var.expires_tag
  }
}

resource "tfe_variable" "lab" {
  for_each        = local.stack_inputs
  key             = each.key
  value           = each.value
  category        = "terraform"
  variable_set_id = tfe_variable_set.lab.id
}

resource "tfe_variable" "license" {
  key             = "tfe_license"
  value           = trimspace(file(var.tfe_license_file))
  category        = "terraform"
  sensitive       = true
  variable_set_id = tfe_variable_set.lab.id
}

# The tfe provider rejects vcs_repo when both oauth_token_id and github_app_installation_id are
# non-null, and `terraform validate` sees variables as unknown, so a single resource driven by
# both variables cannot validate. One resource per VCS connection type avoids that.
resource "tfe_stack" "this" {
  count         = var.create_stack && var.github_app_installation_id != null ? 1 : 0
  name          = var.stack_name
  project_id    = tfe_project.this.id
  agent_pool_id = tfe_agent_pool.this.id

  vcs_repo {
    identifier                 = var.github_repo
    branch                     = var.github_branch
    github_app_installation_id = var.github_app_installation_id
  }

  depends_on = [tfe_agent_pool_allowed_projects.this, tfe_project_variable_set.lab]
}

resource "tfe_stack" "oauth" {
  count         = var.create_stack && var.vcs_oauth_token_id != null ? 1 : 0
  name          = var.stack_name
  project_id    = tfe_project.this.id
  agent_pool_id = tfe_agent_pool.this.id

  vcs_repo {
    identifier     = var.github_repo
    branch         = var.github_branch
    oauth_token_id = var.vcs_oauth_token_id
  }

  depends_on = [tfe_agent_pool_allowed_projects.this, tfe_project_variable_set.lab]
}
