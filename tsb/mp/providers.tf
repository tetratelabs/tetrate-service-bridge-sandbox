terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.infra.outputs.host
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca_certificate)
  token                  = data.terraform_remote_state.infra.outputs.token
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.infra.outputs.host
    cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca_certificate)
    token                  = data.terraform_remote_state.infra.outputs.token
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.infra.outputs.host
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra.outputs.cluster_ca_certificate)
  token                  = data.terraform_remote_state.infra.outputs.token
  load_config_file       = false
}

provider "azurerm" {
  features {}
}