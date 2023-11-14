terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.0.3"
    }
  }
}

provider "kubernetes" {
  host                   = local.infra["outputs"].host
  cluster_ca_certificate = base64decode(local.infra["outputs"].cluster_ca_certificate)
  token                  = local.infra["outputs"].token
}

provider "helm" {
  kubernetes {
    host                   = local.infra["outputs"].host
    cluster_ca_certificate = base64decode(local.infra["outputs"].cluster_ca_certificate)
    token                  = local.infra["outputs"].token
  }
}

provider "kubectl" {
  host                   = local.infra["outputs"].host
  cluster_ca_certificate = base64decode(local.infra["outputs"].cluster_ca_certificate)
  token                  = local.infra["outputs"].token
  load_config_file       = false
}
