locals {
  tags = {
    owner      = var.owner_tag
    expires    = var.expires_tag
    project    = "tf-azure-aks-tfe"
    managed_by = "hcp-terraform-stacks"
  }
}

component "tfe_infra" {
  source = "./modules/tfe-infra"

  inputs = {
    prefix                  = var.prefix
    location                = var.location
    resource_group_name     = var.resource_group_name
    vnet_id                 = var.vnet_id
    lb_subnet_id            = var.lb_subnet_id
    aks_subnet_id           = var.aks_subnet_id
    db_subnet_id            = var.db_subnet_id
    redis_subnet_id         = var.redis_subnet_id
    key_vault_id            = var.key_vault_id
    db_password_secret_name = var.db_password_secret_name
    tfe_hostname            = var.tfe_hostname
    tfe_version             = var.tfe_version
    aks_kubernetes_version  = var.aks_kubernetes_version
    size                    = var.size
    aks_authorized_cidrs    = split(",", var.aks_authorized_cidrs_csv)
    tags                    = local.tags
  }

  providers = {
    azurerm = provider.azurerm.this
    random  = provider.random.this
    local   = provider.local.this
  }
}

component "tfe_install" {
  source = "./modules/tfe-install"

  inputs = {
    tfe_hostname                          = var.tfe_hostname
    tfe_version                           = var.tfe_version
    replica_count                         = component.tfe_infra.replica_count
    pod_requests                          = component.tfe_infra.tfe_pod_requests
    tfe_license                           = var.tfe_license
    lb_subnet_name                        = var.lb_subnet_name
    lb_static_ip                          = var.lb_static_ip
    key_vault_id                          = var.key_vault_id
    tfe_database_host                     = component.tfe_infra.tfe_database_host
    tfe_database_name                     = component.tfe_infra.tfe_database_name
    tfe_database_user                     = component.tfe_infra.tfe_database_user
    tfe_database_password                 = component.tfe_infra.tfe_database_password
    tfe_object_storage_azure_account_name = component.tfe_infra.tfe_object_storage_azure_account_name
    tfe_object_storage_azure_container    = component.tfe_infra.tfe_object_storage_azure_container
    tfe_object_storage_azure_client_id    = component.tfe_infra.tfe_object_storage_azure_client_id
    tfe_redis_host                        = component.tfe_infra.tfe_redis_host
    tfe_redis_password                    = component.tfe_infra.tfe_redis_password
    tfe_redis_use_auth                    = component.tfe_infra.tfe_redis_use_auth
    tfe_redis_sidekiq_host                = component.tfe_infra.tfe_redis_sidekiq_host
    tfe_redis_sidekiq_password            = component.tfe_infra.tfe_redis_sidekiq_password
    tfe_redis_sidekiq_use_auth            = component.tfe_infra.tfe_redis_sidekiq_use_auth
    private_dns_zone_name                 = var.private_dns_zone_name
    resource_group_name                   = var.resource_group_name
    public_dns_zone_name                  = var.public_dns_zone_name
    public_dns_zone_resource_group        = var.public_dns_zone_resource_group
    subscription_id                       = var.subscription_id
  }

  providers = {
    azurerm    = provider.azurerm.this
    kubernetes = provider.kubernetes.this
    helm       = provider.helm.this
    random     = provider.random.this
    acme       = provider.acme.this
  }
}

component "tfe_bootstrap" {
  source = "./modules/tfe-bootstrap"

  inputs = {
    tfe_hostname = component.tfe_install.tfe_hostname
    iact_token   = component.tfe_install.iact_token
    admin_email  = var.admin_email
    key_vault_id = var.key_vault_id
  }

  providers = {
    azurerm   = provider.azurerm.this
    random    = provider.random.this
    terracurl = provider.terracurl.this
  }
}

component "tfe_config" {
  source   = "./modules/tfe-config"
  for_each = var.configure_tfe ? toset(["this"]) : toset([])

  inputs = {
    organization_name           = var.organization_name
    organization_email          = var.organization_email
    platform_team_member_emails = var.platform_team_member_emails
    collaborator_auth_policy    = var.collaborator_auth_policy
  }

  providers = {
    tfe = provider.tfe.this[each.key]
  }
}
