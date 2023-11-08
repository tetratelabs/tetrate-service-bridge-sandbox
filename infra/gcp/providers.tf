terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    } 
    google = {
      version = "~> 4.64.0"
    }
  }
}

provider "google" {
  /* https://github.com/hashicorp/terraform-provider-google/issues/7325
  default_labels = {
  } */
}
