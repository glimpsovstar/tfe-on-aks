locals {
  presets = {
    lab = {
      aks_node_vm_size    = "Standard_D4ds_v5"
      aks_node_count      = 2
      aks_tfe_pool        = false
      postgres_sku        = "GP_Standard_D2ds_v4"
      postgres_ha         = false
      redis_sku           = "Balanced_B0"
      redis_ha            = false
      storage_replication = "ZRS"
      replica_count       = 1
      tfe_pod_requests    = { cpu = "2", memory = "6Gi" }
    }
    small = {
      aks_node_vm_size    = "Standard_D8ds_v5"
      aks_node_count      = 2
      aks_tfe_pool        = false
      postgres_sku        = "GP_Standard_D4ds_v4"
      postgres_ha         = false
      redis_sku           = "Balanced_B3"
      redis_ha            = true
      storage_replication = "ZRS"
      replica_count       = 1
      tfe_pod_requests    = { cpu = "4", memory = "8Gi" }
    }
    production = {
      aks_node_vm_size    = "Standard_D8ds_v5"
      aks_node_count      = 3
      aks_tfe_pool        = true
      postgres_sku        = "GP_Standard_D4ds_v4"
      postgres_ha         = true
      redis_sku           = "Balanced_B3"
      redis_ha            = true
      storage_replication = "ZRS"
      replica_count       = 3
      tfe_pod_requests    = { cpu = "4", memory = "8Gi" }
    }
  }

  # Sidekiq needs cross-slot MULTI and BRPOP; EnterpriseCluster rejects them (CROSSSLOT) and runs stay pending.
  redis_clustering_policy = "NoCluster"

  settings = merge(local.presets[var.size], {
    storage_ip_allow = [for c in var.aks_authorized_cidrs : trimsuffix(c, "/32")]
  })
}

module "tfe" {
  # HashiCorp's HVD module 0.3.0, vendored with one patch (vendor/terraform-enterprise-aks-hvd/PATCHES.md).
  source = "../../vendor/terraform-enterprise-aks-hvd"

  # Common
  resource_group_name   = var.resource_group_name
  create_resource_group = false
  location              = var.location
  friendly_name_prefix  = var.prefix
  common_tags           = var.tags

  # TFE
  tfe_fqdn                   = var.tfe_hostname
  tfe_image_tag              = var.tfe_version
  create_helm_overrides_file = false

  # Networking
  vnet_id          = var.vnet_id
  tfe_lb_subnet_id = var.lb_subnet_id
  aks_subnet_id    = var.aks_subnet_id
  db_subnet_id     = var.db_subnet_id
  redis_subnet_id  = var.redis_subnet_id

  # DNS is owned by tfe-install
  create_tfe_public_dns_record  = false
  create_tfe_private_dns_record = false

  # AKS
  create_aks_cluster                  = true
  aks_kubernetes_version              = var.aks_kubernetes_version
  aks_api_server_authorized_ip_ranges = var.aks_authorized_cidrs
  aks_default_node_pool_vm_size       = local.settings.aks_node_vm_size
  aks_default_node_pool_node_count    = local.settings.aks_node_count
  create_aks_tfe_node_pool            = local.settings.aks_tfe_pool
  aks_tfe_node_pool_vm_size           = "Standard_D8ds_v5"
  aks_tfe_node_pool_node_count        = 3
  aks_workload_identity_enabled       = true
  aks_oidc_issuer_enabled             = true

  # Database
  tfe_database_password_keyvault_id          = var.key_vault_id
  tfe_database_password_keyvault_secret_name = var.db_password_secret_name
  postgres_sku                               = local.settings.postgres_sku
  postgres_enable_high_availability          = local.settings.postgres_ha

  # Redis (Azure Managed Redis, because tfe_version >= 1.0.1)
  redis_managed_sku_name                  = local.settings.redis_sku
  redis_managed_high_availability_enabled = local.settings.redis_ha
  redis_managed_clustering_policy         = local.redis_clustering_policy

  # Object storage
  tfe_object_storage_azure_use_msi = true
  storage_account_replication_type = local.settings.storage_replication
  storage_account_ip_allow         = local.settings.storage_ip_allow
}
