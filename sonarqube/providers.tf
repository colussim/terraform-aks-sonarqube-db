terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.99"
    }
  }
}

provider "kubernetes" {
        config_path    = "~/.kube/config"
        config_context = "se-aks01"
        }