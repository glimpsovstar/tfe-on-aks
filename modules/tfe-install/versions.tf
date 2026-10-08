terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.67" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 3.3" }
    helm       = { source = "hashicorp/helm", version = "~> 3.3" }
    random     = { source = "hashicorp/random", version = "~> 3.9" }
    acme       = { source = "vancluever/acme", version = "~> 3.2" }
  }
}
