terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "azurerm" {
  features {}

  #https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  /* default_tags {
    tags = local.tags
  } */
}
