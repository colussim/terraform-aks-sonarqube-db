terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.99"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
  client_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
  client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
  tenant_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
}


