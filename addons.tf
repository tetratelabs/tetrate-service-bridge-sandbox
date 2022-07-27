terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

module "cert-manager" {
  source                     = "./modules/addons/cert-manager"
  cluster_name               = local.cloud[var.cloud == null ? var.tsb_mp["cloud"] : var.cloud][var.cluster_id == null ? var.tsb_mp["cluster_id"] : var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud == null ? var.tsb_mp["cloud"] : var.cloud][var.cluster_id == null ? var.tsb_mp["cluster_id"] : var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud == null ? var.tsb_mp["cloud"] : var.cloud][var.cluster_id == null ? var.tsb_mp["cluster_id"] : var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud == null ? var.tsb_mp["cloud"] : var.cloud][var.cluster_id == null ? var.tsb_mp["cluster_id"] : var.cluster_id].token
}

module "es" {
  source                     = "./modules/addons/elastic"
  cluster_name               = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].cluster_name
  k8s_host                   = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].host
  k8s_cluster_ca_certificate = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].token
}

module "argocd" {
  source                     = "./modules/addons/argocd"
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
  password                   = var.tsb_password
}


module "keycloak-helm" {
  source                     = "./modules/addons/keycloak-helm"
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
  password                   = var.tsb_password
}

module "keycloak-provider" {
  source   = "./modules/addons/keycloak-provider"
  endpoint = "http://${module.keycloak-helm.host}"
  username = module.keycloak-helm.username
  password = module.keycloak-helm.password
}
