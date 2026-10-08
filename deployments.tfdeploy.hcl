# Stack deployment template. Review every value below before you push.
#
# Values that come from the variable set written by bootstrap/ (or that you create by hand) are
# read through the store block. Values set directly in the deployment block are the ones to edit.

identity_token "azurerm" {
  audience = ["api://AzureADTokenExchange"]
}

# Written by bootstrap/. Values persist in state (.stable) because the licence ends up in a Kubernetes secret.
# CHANGE: "tfe-aks-inputs" must match the variable set name in bootstrap (var.varset_name).
store "varset" "inputs" {
  name     = "tfe-aks-inputs"
  category = "terraform"
}

# The deployment name appears in the OIDC subject of the federated credentials that bootstrap creates
# (var.deployment_name, default "main"). If you rename it here, set the same name in bootstrap.
deployment "main" {
  inputs = {
    identity_token                 = identity_token.azurerm.jwt
    client_id                      = store.varset.inputs.stable.client_id
    tenant_id                      = store.varset.inputs.stable.tenant_id
    subscription_id                = store.varset.inputs.stable.subscription_id
    resource_group_name            = store.varset.inputs.stable.resource_group_name
    location                       = store.varset.inputs.stable.location
    prefix                         = store.varset.inputs.stable.prefix
    vnet_id                        = store.varset.inputs.stable.vnet_id
    lb_subnet_id                   = store.varset.inputs.stable.lb_subnet_id
    lb_subnet_name                 = store.varset.inputs.stable.lb_subnet_name
    aks_subnet_id                  = store.varset.inputs.stable.aks_subnet_id
    db_subnet_id                   = store.varset.inputs.stable.db_subnet_id
    redis_subnet_id                = store.varset.inputs.stable.redis_subnet_id
    key_vault_id                   = store.varset.inputs.stable.key_vault_id
    db_password_secret_name        = store.varset.inputs.stable.db_password_secret_name
    private_dns_zone_name          = store.varset.inputs.stable.private_dns_zone_name
    public_dns_zone_name           = store.varset.inputs.stable.public_dns_zone_name
    public_dns_zone_resource_group = store.varset.inputs.stable.public_dns_zone_resource_group
    tfe_hostname                   = store.varset.inputs.stable.tfe_hostname
    lb_static_ip                   = store.varset.inputs.stable.lb_static_ip
    aks_authorized_cidrs_csv       = store.varset.inputs.stable.aks_authorized_cidrs_csv
    owner_tag                      = store.varset.inputs.stable.owner_tag
    expires_tag                    = store.varset.inputs.stable.expires_tag
    tfe_license                    = store.varset.inputs.stable.tfe_license
    # CHANGE: an AKS version available in your region (az aks get-versions -l <region>) and supported by your TFE release.
    aks_kubernetes_version = "1.36"
    # Sizing preset: "lab", "small" or "production". See docs/architecture.md and docs/production.md.
    size = "lab"
    # CHANGE: email of the first TFE admin user created by the tfe_bootstrap component.
    admin_email = "tfe-admin@example.com"
    # CHANGE: name of the TFE organisation that tfe_config creates in pass 2.
    organization_name = "example-org"
    # CHANGE: contact email for that organisation.
    organization_email = "tfe-admin@example.com"
    # Sample only: the Stack's tfe provider uses the bootstrap admin's user token, which has no 2FA, so "password" is needed.
    # For production use "two_factor_mandatory" once every owner (including the bootstrap admin) has enrolled 2FA, or use SSO.
    collaborator_auth_policy = "password"
    # Two-pass flow. Pass 1 (this value, false): the Stack builds AKS and installs TFE, then tfe_bootstrap creates the first
    # admin and stores its token. Pass 2: once tfe_bootstrap has applied, set this to true and push. The tfe provider can then
    # read the admin token, and tfe_config creates the organisation, projects and team.
    configure_tfe = false
  }
  # Set true to destroy this deployment (approve the plan in HCP Terraform).
  destroy = false
}
