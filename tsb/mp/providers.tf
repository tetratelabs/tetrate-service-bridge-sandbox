terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubernetes" {
  host                   = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].host
  cluster_ca_certificate = base64decode(local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate)
  token                  = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].token
}

provider "helm" {
  kubernetes {
    host                   = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].host
    cluster_ca_certificate = base64decode(local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate)
    token                  = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].token
  }
}

provider "kubectl" {
  host                   = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].host
  cluster_ca_certificate = base64decode(local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate)
  token                  = local.infra[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]]["outputs"].token
  load_config_file       = false
}
