module "tfe_install" {
  source = "../../../modules/tfe-install"

  tfe_hostname                          = var.tfe_hostname
  replica_count                         = local.infra.replica_count
  pod_requests                          = local.infra.tfe_pod_requests
  tfe_license                           = var.tfe_license
  lb_subnet_name                        = var.lb_subnet_name
  lb_static_ip                          = var.lb_static_ip
  key_vault_id                          = var.key_vault_id
  tfe_database_host                     = local.infra.tfe_database_host
  tfe_database_name                     = local.infra.tfe_database_name
  tfe_database_user                     = local.infra.tfe_database_user
  tfe_database_password                 = local.infra.tfe_database_password
  tfe_object_storage_azure_account_name = local.infra.tfe_object_storage_azure_account_name
  tfe_object_storage_azure_container    = local.infra.tfe_object_storage_azure_container
  tfe_object_storage_azure_client_id    = local.infra.tfe_object_storage_azure_client_id
  tfe_redis_host                        = local.infra.tfe_redis_host
  tfe_redis_password                    = local.infra.tfe_redis_password
  tfe_redis_use_auth                    = local.infra.tfe_redis_use_auth
  tfe_redis_sidekiq_host                = local.infra.tfe_redis_sidekiq_host
  tfe_redis_sidekiq_password            = local.infra.tfe_redis_sidekiq_password
  tfe_redis_sidekiq_use_auth            = local.infra.tfe_redis_sidekiq_use_auth
  private_dns_zone_name                 = var.private_dns_zone_name
  resource_group_name                   = var.resource_group_name
  public_dns_zone_name                  = var.public_dns_zone_name
  public_dns_zone_resource_group        = var.public_dns_zone_resource_group
  subscription_id                       = var.subscription_id
  acme_azure_auth_method                = var.acme_azure_auth_method
}

module "tfe_bootstrap" {
  source = "../../../modules/tfe-bootstrap"

  tfe_hostname = module.tfe_install.tfe_hostname
  iact_token   = module.tfe_install.iact_token
  admin_email  = var.admin_email
  key_vault_id = var.key_vault_id
}
