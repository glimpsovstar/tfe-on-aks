# Bring your own AKS (create_aks_cluster = false).
#
# The HVD module 0.3.0 reads the OIDC issuer from the cluster it creates, so it can't federate
# an identity to an existing cluster. In this mode the module gets aks_workload_identity_enabled
# = false, and the identity, Blob role and federated credential are created here instead.

data "azurerm_kubernetes_cluster" "existing" {
  count               = var.create_aks_cluster ? 0 : 1
  name                = var.existing_aks_cluster_name
  resource_group_name = coalesce(var.existing_aks_resource_group_name, var.resource_group_name)

  lifecycle {
    precondition {
      condition     = var.existing_aks_cluster_name != null
      error_message = "Set existing_aks_cluster_name when create_aks_cluster = false."
    }
    postcondition {
      condition     = self.oidc_issuer_enabled && self.oidc_issuer_url != ""
      error_message = "The existing AKS cluster needs the OIDC issuer enabled (az aks update --enable-oidc-issuer --enable-workload-identity)."
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  # Built from the module output, not read with a data source: the name is known at plan time,
  # so a data source would be read before the module has created the account.
  tfe_storage_account_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${module.tfe.tfe_object_storage_azure_account_name}"
}

resource "azurerm_user_assigned_identity" "tfe" {
  count               = var.create_aks_cluster ? 0 : 1
  name                = "${var.prefix}-tfe-aks-msi"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "tfe_blob" {
  count                = var.create_aks_cluster ? 0 : 1
  scope                = local.tfe_storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.tfe[0].principal_id
}

resource "azurerm_federated_identity_credential" "tfe" {
  count                     = var.create_aks_cluster ? 0 : 1
  name                      = "tfe-kube-service-account"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = data.azurerm_kubernetes_cluster.existing[0].oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.tfe[0].id
  # Same subject as the HVD module default; tfe-install fixes the namespace and service account to tfe.
  subject = "system:serviceaccount:tfe:tfe"
}

check "aks_version_set" {
  assert {
    condition     = !var.create_aks_cluster || var.aks_kubernetes_version != null
    error_message = "Set aks_kubernetes_version when create_aks_cluster = true."
  }
}

locals {
  kube = var.create_aks_cluster ? module.tfe.aks_kube_config : {
    host                   = data.azurerm_kubernetes_cluster.existing[0].kube_config[0].host
    cluster_ca_certificate = data.azurerm_kubernetes_cluster.existing[0].kube_config[0].cluster_ca_certificate
    client_certificate     = data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_certificate
    client_key             = data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_key
  }
  aks_cluster_name                   = var.create_aks_cluster ? module.tfe.aks_cluster_name : var.existing_aks_cluster_name
  tfe_object_storage_azure_client_id = var.create_aks_cluster ? module.tfe.tfe_object_storage_azure_client_id : azurerm_user_assigned_identity.tfe[0].client_id
}
