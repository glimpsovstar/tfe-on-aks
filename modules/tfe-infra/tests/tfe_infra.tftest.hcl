mock_provider "azurerm" {}

mock_provider "random" {}
mock_provider "local" {}

override_module {
  target = module.tfe
  outputs = {
    aks_cluster_name = "tflab-aks"
    aks_kube_config = {
      host                   = "https://aks.example:443"
      cluster_ca_certificate = "Y2E="
      client_certificate     = "Y2VydA=="
      client_key             = "a2V5"
    }
    tfe_database_host                     = "pg.postgres.database.azure.com:5432"
    tfe_database_name                     = "tfe"
    tfe_database_user                     = "tfe"
    tfe_database_password                 = "dbpw"
    tfe_object_storage_azure_account_name = "tflabtfeblob"
    tfe_object_storage_azure_container    = "tfeblob"
    tfe_object_storage_azure_client_id    = "33333333-3333-3333-3333-333333333333"
    tfe_redis_host                        = "redis.australiaeast.redis.azure.net"
    tfe_redis_password                    = "r1"
    tfe_redis_use_auth                    = true
    tfe_redis_sidekiq_host                = "sidekiq.australiaeast.redis.azure.net"
    tfe_redis_sidekiq_password            = "r2"
    tfe_redis_sidekiq_use_auth            = true
  }
}

# Existing-AKS mode builds the storage account ID from the subscription.
override_data {
  target = data.azurerm_client_config.current
  values = { subscription_id = "00000000-0000-0000-0000-000000000000" }
}

variables {
  prefix                  = "tflab"
  resource_group_name     = "tflab-tfe-rg"
  vnet_id                 = "/subscriptions/x/vnet"
  lb_subnet_id            = "/subscriptions/x/lb"
  aks_subnet_id           = "/subscriptions/x/aks"
  db_subnet_id            = "/subscriptions/x/db"
  redis_subnet_id         = "/subscriptions/x/redis"
  key_vault_id            = "/subscriptions/x/kv"
  db_password_secret_name = "tfe-db-password"
  tfe_hostname            = "tfe.tfelab.example.com"
  aks_kubernetes_version  = "1.35"
  aks_authorized_cidrs    = ["198.51.100.7/32", "203.0.113.10/32"]
  tags                    = { owner = "test" }
}

run "lab_preset" {
  command = apply

  assert {
    condition = jsonencode(output.effective_settings) == jsonencode({
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
      storage_ip_allow    = ["198.51.100.7", "203.0.113.10"]
    })
    error_message = "lab preset must match spec section 8."
  }
  assert {
    condition     = output.tfe_pod_requests.cpu == "2" && output.tfe_pod_requests.memory == "6Gi"
    error_message = "lab preset must request 2 vCPU / 6Gi so the TFE pod fits Standard_D4ds_v5 nodes (3.86 allocatable vCPU)."
  }
}

run "small_preset" {
  command = apply
  variables { size = "small" }

  assert {
    condition = jsonencode(output.effective_settings) == jsonencode({
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
      storage_ip_allow    = ["198.51.100.7", "203.0.113.10"]
    })
    error_message = "small preset must match spec section 8."
  }
}

run "production_preset" {
  command = apply
  variables { size = "production" }

  assert {
    condition     = output.effective_settings.aks_tfe_pool && output.effective_settings.postgres_ha && output.effective_settings.replica_count == 3 && output.effective_settings.aks_node_count == 3
    error_message = "production preset: TFE node pool, PostgreSQL HA, 3 replicas, 3 nodes."
  }
  assert {
    condition     = output.tfe_pod_requests.cpu == "4" && output.tfe_pod_requests.memory == "8Gi"
    error_message = "production keeps the chart default requests of 4 vCPU / 8Gi."
  }
}

run "kube_credentials_from_kube_config" {
  command = apply

  assert {
    condition     = output.kube_host == "https://aks.example:443"
    error_message = "kube_host must come from kube_config (a local-account cluster has no admin profile)."
  }
  assert {
    condition     = output.kube_client_key == "a2V5" && output.kube_cluster_ca_certificate == "Y2E="
    error_message = "Kube credentials come from the cluster resource's kube_config via the module output, not a data source."
  }
}

run "storage_ip_allow_strips_mask" {
  command = apply

  assert {
    condition     = tolist(output.effective_settings.storage_ip_allow) == tolist(["198.51.100.7", "203.0.113.10"])
    error_message = "Storage ip_rules need plain IPs, not /32 CIDRs."
  }
}

run "rejects_v_prefixed_version" {
  command = plan
  variables { tfe_version = "v2.0.8" }
  expect_failures = [var.tfe_version]
}

run "rejects_1_0_0_version" {
  command = plan
  variables { tfe_version = "1.0.0" }
  expect_failures = [var.tfe_version]
}

run "rejects_two_part_version" {
  command = plan
  variables { tfe_version = "2.0" }
  expect_failures = [var.tfe_version]
}

run "rejects_latest_version" {
  command = plan
  variables { tfe_version = "latest" }
  expect_failures = [var.tfe_version]
}

run "accepts_1_0_1_version" {
  command = plan
  variables { tfe_version = "1.0.1" }
}

run "rejects_unknown_size" {
  command = plan
  variables { size = "huge" }
  expect_failures = [var.size]
}

run "rejects_prefix_with_tfe" {
  command = plan
  variables { prefix = "tfelab" }
  expect_failures = [var.prefix]
}

run "rejects_empty_authorized_cidrs" {
  command = plan
  variables { aks_authorized_cidrs = [] }
  expect_failures = [var.aks_authorized_cidrs]
}

run "redis_is_not_clustered" {
  command = plan

  assert {
    condition     = local.redis_clustering_policy == "NoCluster"
    error_message = "Sidekiq needs cross-slot MULTI and BRPOP, so Azure Managed Redis must be NoCluster (EnterpriseCluster gives CROSSSLOT and runs stay pending)."
  }
}

run "existing_aks_cluster" {
  command = apply

  variables {
    create_aks_cluster               = false
    existing_aks_cluster_name        = "platform-aks"
    existing_aks_resource_group_name = "platform-rg"
  }

  override_data {
    target = data.azurerm_kubernetes_cluster.existing[0]
    values = {
      oidc_issuer_enabled = true
      oidc_issuer_url     = "https://oidc.example/issuer/"
      kube_config = [{
        host                   = "https://platform-aks.example:443"
        cluster_ca_certificate = "Y2E="
        client_certificate     = "Y2VydA=="
        client_key             = "a2V5"
        username               = "u"
        password               = "p"
      }]
    }
  }

  override_resource {
    target = azurerm_user_assigned_identity.tfe[0]
    values = {
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/tflab-tfe-aks-msi"
      client_id = "44444444-4444-4444-4444-444444444444"
    }
  }

  assert {
    condition     = output.aks_cluster_name == "platform-aks"
    error_message = "aks_cluster_name should be the existing cluster."
  }
  assert {
    condition     = nonsensitive(output.kube_host) == "https://platform-aks.example:443"
    error_message = "kube credentials should come from the existing cluster."
  }
  assert {
    condition     = output.tfe_object_storage_azure_client_id == "44444444-4444-4444-4444-444444444444"
    error_message = "Blob client ID should be the identity created for the existing cluster."
  }
  assert {
    condition     = azurerm_federated_identity_credential.tfe[0].issuer == "https://oidc.example/issuer/" && azurerm_federated_identity_credential.tfe[0].subject == "system:serviceaccount:tfe:tfe"
    error_message = "Federated credential must trust the existing cluster's issuer for tfe:tfe."
  }
}

run "existing_aks_needs_oidc" {
  command = plan

  variables {
    create_aks_cluster        = false
    existing_aks_cluster_name = "platform-aks"
  }

  override_data {
    target = data.azurerm_kubernetes_cluster.existing[0]
    values = { oidc_issuer_enabled = false, oidc_issuer_url = "" }
  }

  expect_failures = [data.azurerm_kubernetes_cluster.existing]
}
