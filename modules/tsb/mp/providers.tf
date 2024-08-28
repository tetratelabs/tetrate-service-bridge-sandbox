terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.3"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.116.0"
    }
  }
}