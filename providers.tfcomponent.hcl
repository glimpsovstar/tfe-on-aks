required_providers {
  azurerm    = { source = "hashicorp/azurerm", version = "~> 4.67" }
  kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.3" }
  helm       = { source = "hashicorp/helm", version = "~> 3.3" }
  random     = { source = "hashicorp/random", version = "~> 3.9" }
  local      = { source = "hashicorp/local", version = "~> 2.9" }
  acme       = { source = "vancluever/acme", version = "~> 3.2" }
  terracurl  = { source = "devops-rob/terracurl", version = "~> 2.11" }
  tfe        = { source = "hashicorp/tfe", version = "~> 0.81" }
}

provider "azurerm" "this" {
  config {
    features {}
    resource_provider_registrations = "none"
    use_cli                         = false
    use_oidc                        = true
    oidc_token                      = var.identity_token
    client_id                       = var.client_id
    tenant_id                       = var.tenant_id
    subscription_id                 = var.subscription_id
  }
}

provider "kubernetes" "this" {
  config {
    host                   = component.tfe_infra.kube_host
    cluster_ca_certificate = base64decode(component.tfe_infra.kube_cluster_ca_certificate)
    client_certificate     = base64decode(component.tfe_infra.kube_client_certificate)
    client_key             = base64decode(component.tfe_infra.kube_client_key)
  }
}

provider "helm" "this" {
  config {
    kubernetes = {
      host                   = component.tfe_infra.kube_host
      cluster_ca_certificate = base64decode(component.tfe_infra.kube_cluster_ca_certificate)
      client_certificate     = base64decode(component.tfe_infra.kube_client_certificate)
      client_key             = base64decode(component.tfe_infra.kube_client_key)
    }
  }
}

provider "random" "this" {}

provider "local" "this" {}

provider "acme" "this" {
  config {
    server_url = "https://acme-v02.api.letsencrypt.org/directory"
  }
}

provider "terracurl" "this" {}

# Let's Encrypt certificate is publicly trusted, so no CA setting is needed (the tfe provider has none).
provider "tfe" "this" {
  for_each = var.configure_tfe ? toset(["this"]) : toset([])

  config {
    hostname = component.tfe_install.tfe_hostname
    token    = component.tfe_bootstrap.admin_token
  }
}
