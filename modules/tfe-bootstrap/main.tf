resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#%-_"
}

# Called exactly once: no read, no delete. Re-plans are no-ops because of ignore_changes.
resource "terracurl_request" "initial_admin" {
  name               = "tfe-initial-admin-user"
  url                = "https://${var.tfe_hostname}/admin/initial-admin-user"
  method             = "POST"
  request_parameters = { token = var.iact_token }
  headers_wo         = { "Content-Type" = "application/json" }
  headers_wo_version = 1

  request_body_wo = jsonencode({
    username = var.admin_username
    email    = var.admin_email
    password = random_password.admin.result
  })
  request_body_wo_version = 1

  response_codes     = ["200", "201"]
  response_sensitive = true
  skip_read          = true
  skip_destroy       = true
  max_retry          = 10
  retry_interval     = 30

  lifecycle {
    ignore_changes = [url, request_parameters, headers, headers_wo_version, request_body_wo_version]
  }
}

locals {
  admin_token = jsondecode(terracurl_request.initial_admin.sensitive_response).token
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "admin_token" {
  name         = "tfe-admin-token"
  value        = local.admin_token
  key_vault_id = var.key_vault_id
}

# tflint-ignore: azurerm_resources_missing_prevent_destroy # lab is torn down with terraform destroy
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "tfe-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
}
