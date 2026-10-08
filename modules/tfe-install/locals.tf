locals {
  # Same rule as the HVD module's locals_helm_overrides.tf: semver >= 1.2.1 uses the readiness API.
  v_parts            = [for p in split(".", var.tfe_version) : tonumber(p)]
  readiness_uses_api = local.v_parts[0] > 1 || (local.v_parts[0] == 1 && (local.v_parts[1] > 2 || (local.v_parts[1] == 2 && local.v_parts[2] >= 1)))
  health_check_path  = local.readiness_uses_api ? "/api/v1/health/readiness" : "/_health_check"

  # Azure Managed Redis: port 10000, user "default" (HVD module 0.3.0 defaults).
  redis_port = 10000
  redis_user = "default"

  helm_values = {
    replicaCount = var.replica_count
    resources = {
      requests = { cpu = var.pod_requests.cpu, memory = var.pod_requests.memory }
    }
    imagePullSecrets = [{ name = "terraform-enterprise" }]
    image = {
      repository = "images.releases.hashicorp.com"
      name       = "hashicorp/terraform-enterprise"
      tag        = var.tfe_version
    }
    # AKS workload identity, as in the TFE Kubernetes docs: client ID on the service account, use label on it and the pod.
    # No TFE_OBJECT_STORAGE_AZURE_USE_MSI: it makes TFE ask the node's IMDS endpoint and skip the federated token.
    serviceAccount = {
      enabled     = true
      annotations = { "azure.workload.identity/client-id" = var.tfe_object_storage_azure_client_id }
      labels      = { "azure.workload.identity/use" = "true" }
    }
    pod = {
      labels = { "azure.workload.identity/use" = "true" }
      # tfe-secrets is outside the chart, so Helm can't see it change. A hash of it in the pod
      # template rolls TFE when a secret changes (e.g. new Redis keys). The hash reveals nothing.
      annotations = { "checksum/tfe-secrets" = nonsensitive(sha256(jsonencode(kubernetes_secret_v1.tfe_secrets.data))) }
    }
    tls = {
      certificateSecret = "tfe-certs"
    }
    tfe = {
      privateHttpPort  = 8080
      privateHttpsPort = 8443
      metrics = {
        enable    = true
        httpPort  = 9090
        httpsPort = 9091
      }
    }
    service = {
      type = "LoadBalancer"
      port = 443
      annotations = {
        "service.beta.kubernetes.io/azure-load-balancer-internal"                  = "true"
        "service.beta.kubernetes.io/azure-load-balancer-internal-subnet"           = var.lb_subnet_name
        "service.beta.kubernetes.io/azure-load-balancer-ipv4"                      = var.lb_static_ip
        "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = local.health_check_path
      }
    }
    env = {
      secretRefs = [{ name = "tfe-secrets" }]
      variables = {
        TFE_HOSTNAME                          = var.tfe_hostname
        TFE_DATABASE_HOST                     = var.tfe_database_host
        TFE_DATABASE_NAME                     = var.tfe_database_name
        TFE_DATABASE_USER                     = var.tfe_database_user
        TFE_DATABASE_PARAMETERS               = "sslmode=require"
        TFE_OBJECT_STORAGE_TYPE               = "azure"
        TFE_OBJECT_STORAGE_AZURE_ACCOUNT_NAME = var.tfe_object_storage_azure_account_name
        TFE_OBJECT_STORAGE_AZURE_CONTAINER    = var.tfe_object_storage_azure_container
        TFE_REDIS_HOST                        = "${var.tfe_redis_host}:${local.redis_port}"
        TFE_REDIS_USER                        = local.redis_user
        TFE_REDIS_USE_AUTH                    = tostring(var.tfe_redis_use_auth)
        TFE_REDIS_USE_TLS                     = "true"
        TFE_REDIS_SIDEKIQ_HOST                = "${var.tfe_redis_sidekiq_host}:${local.redis_port}"
        TFE_REDIS_SIDEKIQ_USER                = local.redis_user
        TFE_REDIS_SIDEKIQ_USE_AUTH            = tostring(var.tfe_redis_sidekiq_use_auth)
        TFE_REDIS_SIDEKIQ_USE_TLS             = "true"
      }
    }
  }
}
