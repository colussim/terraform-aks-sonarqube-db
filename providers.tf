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
  subscription_id = "1d7d141b-b12f-474e-8ef5-231f9a6e8367"
  client_id       = "c5b5fe61-329b-4f88-a41c-18691ab72a88"
  client_secret   = "Zzh8Q~4b1XYuUBsObxgEpL3AIfGULuWz9qHLEb~U" 
  tenant_id       = "75622d57-788f-4dd3-b33c-739f625e6311"
}


