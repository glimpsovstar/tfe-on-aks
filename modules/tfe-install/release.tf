resource "helm_release" "tfe" {
  name       = "terraform-enterprise"
  namespace  = kubernetes_namespace_v1.tfe.metadata[0].name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "terraform-enterprise"
  version    = var.chart_version
  values     = [yamlencode(local.helm_values)]
  wait       = true
  timeout    = 900
  # Uninstall on a failed install so the next apply can install again (a failed release otherwise blocks the name).
  atomic = true

  depends_on = [
    kubernetes_secret_v1.tfe_secrets,
    kubernetes_secret_v1.pull,
    kubernetes_secret_v1.tfe_certs,
  ]
}
