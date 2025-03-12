terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    } 
    google = {
      version = "~> 5.45.0"
    }
  }
}
