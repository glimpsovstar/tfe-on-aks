resource "acme_registration" "this" {}

resource "acme_certificate" "tfe" {
  account_key_pem               = acme_registration.this.account_key_pem
  common_name                   = var.tfe_hostname
  key_type                      = "RSA2048"
  min_days_remaining            = 30
  recursive_nameservers         = ["8.8.8.8:53", "1.1.1.1:53"]
  revoke_certificate_on_destroy = true

  dns_challenge {
    provider = "azuredns"
    config = {
      AZURE_AUTH_METHOD         = var.acme_azure_auth_method
      AZURE_SUBSCRIPTION_ID     = var.subscription_id
      AZURE_RESOURCE_GROUP      = var.public_dns_zone_resource_group
      AZURE_ZONE_NAME           = var.public_dns_zone_name
      AZURE_TTL                 = "60"
      AZURE_PROPAGATION_TIMEOUT = "300"
    }
  }
}

resource "kubernetes_secret_v1" "tfe_certs" {
  metadata {
    name      = "tfe-certs"
    namespace = kubernetes_namespace_v1.tfe.metadata[0].name
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = "${acme_certificate.tfe.certificate_pem}${acme_certificate.tfe.issuer_pem}"
    "tls.key" = acme_certificate.tfe.private_key_pem
  }
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "tls_fullchain" {
  name         = "tfe-tls-fullchain"
  value        = "${acme_certificate.tfe.certificate_pem}${acme_certificate.tfe.issuer_pem}"
  key_vault_id = var.key_vault_id
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "tls_key" {
  name         = "tfe-tls-key"
  value        = acme_certificate.tfe.private_key_pem
  key_vault_id = var.key_vault_id
}

resource "azurerm_private_dns_a_record" "tfe" {
  name                = split(".", var.tfe_hostname)[0]
  zone_name           = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [var.lb_static_ip]
}
