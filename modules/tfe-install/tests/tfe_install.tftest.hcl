mock_provider "azurerm" {}
mock_provider "kubernetes" {}
mock_provider "helm" {}
mock_provider "random" {}
mock_provider "acme" {}

variables {
  tfe_hostname                          = "tfe.tfelab.example.com"
  replica_count                         = 1
  tfe_license                           = "fake-licence"
  lb_subnet_name                        = "tflab-lb"
  lb_static_ip                          = "10.40.0.10"
  key_vault_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tflab-tfe-rg/providers/Microsoft.KeyVault/vaults/tflabkv"
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
  private_dns_zone_name                 = "tfelab.example.com"
  resource_group_name                   = "tflab-tfe-rg"
  public_dns_zone_name                  = "example.com"
  public_dns_zone_resource_group        = "dns-rg"
  subscription_id                       = "00000000-0000-0000-0000-000000000000"
}

run "helm_env_matches_hvd_template" {
  command = apply

  assert {
    condition = (
      local.helm_values.env.variables.TFE_HOSTNAME == "tfe.tfelab.example.com" &&
      local.helm_values.env.variables.TFE_DATABASE_HOST == "pg.postgres.database.azure.com:5432" &&
      local.helm_values.env.variables.TFE_DATABASE_PARAMETERS == "sslmode=require" &&
      local.helm_values.env.variables.TFE_OBJECT_STORAGE_TYPE == "azure" &&
      local.helm_values.env.variables.TFE_REDIS_HOST == "redis.australiaeast.redis.azure.net:10000" &&
      local.helm_values.env.variables.TFE_REDIS_USER == "default" &&
      local.helm_values.env.variables.TFE_REDIS_USE_TLS == "true" &&
      local.helm_values.env.variables.TFE_REDIS_SIDEKIQ_HOST == "sidekiq.australiaeast.redis.azure.net:10000" &&
      local.helm_values.env.variables.TFE_REDIS_SIDEKIQ_USER == "default" &&
      local.helm_values.env.variables.TFE_REDIS_SIDEKIQ_USE_TLS == "true"
    )
    error_message = "Helm env must reproduce the HVD module's helm overrides for Managed Redis."
  }
}

run "pod_requests_default_is_chart_default" {
  command = apply

  assert {
    condition     = local.helm_values.resources.requests.cpu == "4" && local.helm_values.resources.requests.memory == "8Gi"
    error_message = "Default pod requests must be the chart default (4 / 8Gi)."
  }
}

run "pod_requests_rendered_in_values_yaml" {
  command = apply
  variables {
    pod_requests = { cpu = "2", memory = "6Gi" }
  }

  assert {
    condition     = strcontains(output.helm_values_yaml, "\"cpu\": \"2\"") && strcontains(output.helm_values_yaml, "\"memory\": \"6Gi\"")
    error_message = "helm_values_yaml must contain the pod requests."
  }
}

run "workload_identity_wiring" {
  command = apply

  assert {
    condition = (
      local.helm_values.serviceAccount.annotations["azure.workload.identity/client-id"] == "33333333-3333-3333-3333-333333333333" &&
      local.helm_values.serviceAccount.labels["azure.workload.identity/use"] == "true" &&
      local.helm_values.pod.labels["azure.workload.identity/use"] == "true"
    )
    error_message = "Service account annotation, and the use label on both service account and pod, are required for workload identity."
  }

  # TFE_OBJECT_STORAGE_AZURE_USE_MSI makes TFE call the node's IMDS endpoint instead of using the federated token (live failure: "Identity not found").
  assert {
    condition     = !contains(keys(local.helm_values.env.variables), "TFE_OBJECT_STORAGE_AZURE_USE_MSI") && !contains(keys(local.helm_values.env.variables), "TFE_OBJECT_STORAGE_AZURE_CLIENT_ID")
    error_message = "Workload identity must not set the MSI env variables."
  }
}

run "internal_lb_annotations" {
  command = apply

  assert {
    condition = (
      local.helm_values.service.annotations["service.beta.kubernetes.io/azure-load-balancer-internal"] == "true" &&
      local.helm_values.service.annotations["service.beta.kubernetes.io/azure-load-balancer-internal-subnet"] == "tflab-lb" &&
      local.helm_values.service.annotations["service.beta.kubernetes.io/azure-load-balancer-ipv4"] == "10.40.0.10" &&
      local.helm_values.service.type == "LoadBalancer"
    )
    error_message = "Service must be an internal LB on the static IP in the LB subnet."
  }
}

run "probe_path_readiness_for_2_0_8" {
  command = apply

  assert {
    condition     = local.helm_values.service.annotations["service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"] == "/api/v1/health/readiness"
    error_message = "TFE >= 1.2.1 uses the readiness API."
  }
}

run "probe_path_legacy_for_1_1_0" {
  command = apply
  variables { tfe_version = "1.1.0" }

  assert {
    condition     = local.helm_values.service.annotations["service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"] == "/_health_check"
    error_message = "TFE < 1.2.1 uses /_health_check."
  }
}

run "tfe_secrets_keys" {
  command = apply

  assert {
    condition = toset(keys(kubernetes_secret_v1.tfe_secrets.data)) == toset([
      "TFE_LICENSE", "TFE_ENCRYPTION_PASSWORD", "TFE_DATABASE_PASSWORD",
      "TFE_REDIS_PASSWORD", "TFE_REDIS_SIDEKIQ_PASSWORD", "TFE_IACT_TOKEN",
    ])
    error_message = "tfe-secrets must hold exactly the six keys."
  }
  assert {
    condition     = kubernetes_secret_v1.tfe_secrets.data["TFE_REDIS_PASSWORD"] == "r1" && kubernetes_secret_v1.tfe_secrets.data["TFE_REDIS_SIDEKIQ_PASSWORD"] == "r2"
    error_message = "Redis passwords come from tfe-infra outputs."
  }
}

run "pull_secret_for_hashicorp_registry" {
  command = apply

  assert {
    condition     = kubernetes_secret_v1.pull.type == "kubernetes.io/dockerconfigjson" && kubernetes_secret_v1.pull.metadata[0].name == "terraform-enterprise"
    error_message = "Pull secret must be the chart's default name and type."
  }
  assert {
    condition     = jsondecode(kubernetes_secret_v1.pull.data[".dockerconfigjson"]).auths["images.releases.hashicorp.com"].username == "terraform"
    error_message = "Registry user is 'terraform' with the licence as password."
  }
}

run "acme_uses_public_resolvers_and_msi" {
  command = apply

  assert {
    condition     = acme_certificate.tfe.recursive_nameservers == tolist(["8.8.8.8:53", "1.1.1.1:53"])
    error_message = "Inside the VNet the private zone shadows the subdomain; the pre-check must use public resolvers."
  }
  assert {
    condition     = acme_certificate.tfe.dns_challenge[0].provider == "azuredns" && acme_certificate.tfe.dns_challenge[0].config["AZURE_AUTH_METHOD"] == "msi" && acme_certificate.tfe.dns_challenge[0].config["AZURE_ZONE_NAME"] == "example.com"
    error_message = "DNS-01 must use azuredns with MSI against the public zone."
  }
  assert {
    condition     = acme_certificate.tfe.common_name == "tfe.tfelab.example.com" && acme_certificate.tfe.min_days_remaining == 30
    error_message = "Certificate is for the TFE hostname and renews 30 days before expiry."
  }
}

run "tls_secret_and_dns_record" {
  command = apply

  assert {
    condition     = kubernetes_secret_v1.tfe_certs.type == "kubernetes.io/tls" && kubernetes_secret_v1.tfe_certs.metadata[0].name == "tfe-certs"
    error_message = "TLS secret must be kubernetes.io/tls named tfe-certs."
  }
  assert {
    condition     = azurerm_private_dns_a_record.tfe.name == "tfe" && azurerm_private_dns_a_record.tfe.zone_name == "tfelab.example.com" && tolist(azurerm_private_dns_a_record.tfe.records) == tolist(["10.40.0.10"])
    error_message = "A record tfe.<private zone> must point at the LB static IP."
  }
}

run "helm_release_pinned_and_waits" {
  command = apply

  assert {
    condition     = helm_release.tfe.repository == "https://helm.releases.hashicorp.com" && helm_release.tfe.chart == "terraform-enterprise" && helm_release.tfe.version == "2.0.8"
    error_message = "Chart must come from the HashiCorp repo at the pinned version."
  }
  assert {
    condition     = helm_release.tfe.wait && helm_release.tfe.timeout == 900
    error_message = "Release must wait for ready pods (15 minutes)."
  }
}

run "rejects_unknown_acme_auth" {
  command = plan
  variables { acme_azure_auth_method = "env" }
  expect_failures = [var.acme_azure_auth_method]
}

run "rejects_v_prefixed_version" {
  command = plan
  variables { tfe_version = "v2.0.8" }
  expect_failures = [var.tfe_version]
}

run "rejects_non_tfe_namespace" {
  command = plan
  variables { namespace = "tfe-prod" }
  expect_failures = [var.namespace]
}

run "helm_release_cleans_up_on_failure" {
  command = plan

  assert {
    condition     = helm_release.tfe.atomic == true
    error_message = "A failed install must uninstall itself, or the next apply hits 'cannot re-use a name that is still in use'."
  }
}

run "secrets_checksum_baseline" {
  command = apply

  assert {
    condition     = length(local.helm_values.pod.annotations["checksum/tfe-secrets"]) == 64
    error_message = "Pod template carries a sha256 of tfe-secrets so a secret change restarts TFE."
  }
}

# New Redis access keys (e.g. Redis recreated) must roll the TFE pod, or it keeps the old password.
run "secrets_change_rolls_pod" {
  command = apply
  variables { tfe_redis_sidekiq_password = "r2-rotated" }

  assert {
    condition     = output.helm_values_yaml != run.secrets_checksum_baseline.helm_values_yaml
    error_message = "A changed secret must change the pod template."
  }
}
