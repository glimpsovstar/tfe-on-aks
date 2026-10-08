mock_provider "azurerm" {}
mock_provider "random" {}
mock_provider "terracurl" {
  mock_resource "terracurl_request" {
    defaults = {
      sensitive_response = "{\"status\":\"created\",\"token\":\"tfe-admin-api-token\"}"
    }
  }
}

variables {
  tfe_hostname = "tfe.tfelab.example.com"
  iact_token   = "iact-123"
  admin_email  = "admin@example.com"
  key_vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv"
}

run "posts_initial_admin_once" {
  command = apply

  assert {
    condition     = terracurl_request.initial_admin.method == "POST" && terracurl_request.initial_admin.url == "https://tfe.tfelab.example.com/admin/initial-admin-user"
    error_message = "Must POST to the initial admin endpoint."
  }
  assert {
    condition     = terracurl_request.initial_admin.request_parameters["token"] == "iact-123"
    error_message = "IACT goes in the token query parameter."
  }
  assert {
    condition     = terracurl_request.initial_admin.skip_read && terracurl_request.initial_admin.skip_destroy && terracurl_request.initial_admin.response_sensitive
    error_message = "No read, no destroy call, sensitive response."
  }
}

run "token_extracted_and_stored" {
  command = apply

  assert {
    condition     = output.admin_token == "tfe-admin-api-token"
    error_message = "admin_token must be parsed from the response."
  }
  assert {
    condition     = azurerm_key_vault_secret.admin_token.name == "tfe-admin-token" && azurerm_key_vault_secret.admin_password.name == "tfe-admin-password"
    error_message = "Token and password are stored in Key Vault."
  }
}

run "ignore_changes_guard" {
  command = apply
  variables { iact_token = "a-different-token" }

  assert {
    condition     = terracurl_request.initial_admin.request_parameters["token"] == "iact-123"
    error_message = "ignore_changes must keep the original request; a new IACT must not replace the resource."
  }
}

run "headers_are_write_only" {
  command = plan

  assert {
    condition     = terracurl_request.initial_admin.headers == null && terracurl_request.initial_admin.headers_wo_version == 1
    error_message = "Headers go in headers_wo (not stored in state), with headers_wo_version set."
  }
}
