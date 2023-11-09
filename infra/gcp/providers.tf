terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.3"
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