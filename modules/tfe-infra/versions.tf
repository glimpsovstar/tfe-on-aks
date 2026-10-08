terraform {
  required_version = ">= 1.11"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.67" }
    random  = { source = "hashicorp/random", version = "~> 3.9" }
    # The HVD module uses local_file (count = 0 here) without declaring the provider.
    # Declaring it lets the Stack pass it in explicitly.
    local = { source = "hashicorp/local", version = "~> 2.9" }
  }
}
