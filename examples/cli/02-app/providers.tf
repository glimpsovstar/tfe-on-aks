terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.67" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.3" }
    helm       = { source = "hashicorp/helm", version = "~> 3.3" }
    random     = { source = "hashicorp/random", version = "~> 3.9" }
    acme       = { source = "vancluever/acme", version = "~> 3.2" }
    terracurl  = { source = "devops-rob/terracurl", version = "~> 2.11" }
  }
}

data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.state_resource_group_name
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "tfe/01-infra.tfstate"
    use_azuread_auth     = true
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "kubernetes" {
  host                   = local.infra.kube_host
  cluster_ca_certificate = base64decode(local.infra.kube_cluster_ca_certificate)
  client_certificate     = base64decode(local.infra.kube_client_certificate)
  client_key             = base64decode(local.infra.kube_client_key)
}

provider "helm" {
  kubernetes = {
    host                   = local.infra.kube_host
    cluster_ca_certificate = base64decode(local.infra.kube_cluster_ca_certificate)
    client_certificate     = base64decode(local.infra.kube_client_certificate)
    client_key             = base64decode(local.infra.kube_client_key)
  }
}

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}
