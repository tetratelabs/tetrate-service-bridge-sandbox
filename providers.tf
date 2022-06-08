provider "azurerm" {
  features {}
}

provider "aws" {
  region = var.aws_region
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}
