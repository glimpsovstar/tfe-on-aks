resource "kubernetes_namespace_v1" "tfe" {
  metadata {
    name = var.namespace
  }
}

resource "random_password" "encryption" {
  length  = 32
  special = false
}

resource "random_password" "iact" {
  length  = 32
  special = false
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "encryption" {
  name         = "tfe-encryption-password"
  value        = random_password.encryption.result
  key_vault_id = var.key_vault_id
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "iact" {
  name         = "tfe-iact-token"
  value        = random_password.iact.result
  key_vault_id = var.key_vault_id
}

resource "kubernetes_secret_v1" "tfe_secrets" {
  metadata {
    name      = "tfe-secrets"
    namespace = kubernetes_namespace_v1.tfe.metadata[0].name
  }
  data = {
    TFE_LICENSE                = var.tfe_license
    TFE_ENCRYPTION_PASSWORD    = random_password.encryption.result
    TFE_DATABASE_PASSWORD      = var.tfe_database_password
    TFE_REDIS_PASSWORD         = var.tfe_redis_password
    TFE_REDIS_SIDEKIQ_PASSWORD = var.tfe_redis_sidekiq_password
    TFE_IACT_TOKEN             = random_password.iact.result
  }
}

resource "kubernetes_secret_v1" "pull" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace_v1.tfe.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "images.releases.hashicorp.com" = {
          username = "terraform"
          password = var.tfe_license
          auth     = base64encode("terraform:${var.tfe_license}")
        }
      }
    })
  }
}
