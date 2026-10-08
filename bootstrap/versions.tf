terraform {
  required_version = ">= 1.11"

  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.67" }
    tfe     = { source = "hashicorp/tfe", version = "~> 0.81" }
    random  = { source = "hashicorp/random", version = "~> 3.9" }
    time    = { source = "hashicorp/time", version = "~> 0.14" }
    tls     = { source = "hashicorp/tls", version = "~> 4.4" }
  }
}
