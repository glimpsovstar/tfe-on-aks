terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm   = { source = "hashicorp/azurerm", version = "~> 4.67" }
    random    = { source = "hashicorp/random", version = "~> 3.9" }
    terracurl = { source = "devops-rob/terracurl", version = "~> 2.11" }
  }
}
