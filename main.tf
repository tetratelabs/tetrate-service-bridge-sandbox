module "azure_base" {
  source         = "./modules/azure/base"
  name_prefix    = var.name_prefix
  location       = var.location
  cidr           = var.cidr
  clusters_count = 1 + var.app_clusters_count
}

module "azure_jumpbox" {
  source                  = "./modules/azure/jumpbox"
  name_prefix             = var.name_prefix
  location                = var.location
  resource_group_name     = module.azure_base.resource_group_name
  cidr                    = var.cidr
  vnet_subnet             = module.azure_base.vnet_subnets[0]
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.azure_base.registry
  registry_username       = module.azure_base.registry_username
  registry_password       = module.azure_base.registry_password
}

module "azure_k8s" {
  count               = 1 + var.app_clusters_count
  source              = "./modules/azure/k8s"
  resource_group_name = module.azure_base.resource_group_name
  location            = var.location
  name_prefix         = var.name_prefix
  cluster_name        = "${substr(var.name_prefix, 0, min(length("${var.name_prefix}"), 6))}${count.index + 1}"
  vnet_subnet         = module.azure_base.vnet_subnets[count.index]
  registry_id         = module.azure_base.registry_id
  depends_on          = [module.azure_jumpbox]
}

module "cert-manager" {
  source                     = "./modules/addons/cert-manager"
  k8s_host                   = module.azure_k8s.0.host
  k8s_cluster_ca_certificate = module.azure_k8s.0.cluster_ca_certificate
  k8s_client_certificate     = module.azure_k8s.0.client_certificate
  k8s_client_key             = module.azure_k8s.0.client_key
  tsb_fqdn                   = var.tsb_fqdn
}

module "es" {
  source                     = "./modules/addons/elastic"
  k8s_host                   = module.azure_k8s.0.host
  k8s_cluster_ca_certificate = module.azure_k8s.0.cluster_ca_certificate
  k8s_client_certificate     = module.azure_k8s.0.client_certificate
  k8s_client_key             = module.azure_k8s.0.client_key
}

module "argocd" {
  source                     = "./modules/addons/argocd"
  cluster_name               = element(module.azure_k8s, var.cluster_id).cluster_name
  k8s_host                   = element(module.azure_k8s, var.cluster_id).host
  k8s_cluster_ca_certificate = element(module.azure_k8s, var.cluster_id).cluster_ca_certificate
  k8s_client_certificate     = element(module.azure_k8s, var.cluster_id).client_certificate
  k8s_client_key             = element(module.azure_k8s, var.cluster_id).client_key
  tsb_password               = var.tsb_password
}

module "aws_dns" {
  source      = "./modules/aws/dns"
  dns_zone    = var.dns_zone
  tsb_fqdn    = var.tsb_fqdn
  tsb_mp_host = module.tsb_mp.host
}

module "tsb_mp" {
  source                     = "./modules/tsb/mp"
  name_prefix                = var.name_prefix
  cluster_name               = module.azure_k8s.0.cluster_name
  jumpbox_host               = module.azure_jumpbox.public_ip
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = module.azure_jumpbox.pkey
  tsb_version                = var.tsb_version
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  tsb_helm_username          = var.tsb_helm_username != null ? var.tsb_helm_username : var.tsb_image_sync_username
  tsb_helm_password          = var.tsb_helm_password != null ? var.tsb_helm_password : var.tsb_image_sync_apikey
  registry                   = module.azure_base.registry
  k8s_host                   = module.azure_k8s.0.host
  k8s_cluster_ca_certificate = module.azure_k8s.0.cluster_ca_certificate
  k8s_client_certificate     = module.azure_k8s.0.client_certificate
  k8s_client_key             = module.azure_k8s.0.client_key
}

module "tsb_cp" {
  source                     = "./modules/tsb/cp"
  cluster_id                 = var.cluster_id
  name_prefix                = var.name_prefix
  cluster_name               = element(module.azure_k8s, var.cluster_id).cluster_name
  jumpbox_host               = module.azure_jumpbox.public_ip
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = module.azure_jumpbox.pkey
  tsb_version                = var.tsb_version
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_mp_host                = module.tsb_mp.host
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_cacert                 = module.tsb_mp.tsb_cacert
  istiod_cacerts_tls_crt     = module.tsb_mp.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key     = module.tsb_mp.istiod_cacerts_tls_key
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  tsb_helm_username          = var.tsb_helm_username != null ? var.tsb_helm_username : var.tsb_image_sync_username
  tsb_helm_password          = var.tsb_helm_password != null ? var.tsb_helm_password : var.tsb_image_sync_apikey
  registry                   = module.azure_base.registry
  es_host                    = module.tsb_mp.es_host
  es_username                = module.tsb_mp.es_username
  es_password                = module.tsb_mp.es_password
  es_cacert                  = module.tsb_mp.es_cacert
  k8s_host                   = element(module.azure_k8s, var.cluster_id).host
  k8s_cluster_ca_certificate = element(module.azure_k8s, var.cluster_id).cluster_ca_certificate
  k8s_client_certificate     = element(module.azure_k8s, var.cluster_id).client_certificate
  k8s_client_key             = element(module.azure_k8s, var.cluster_id).client_key
}


module "app_bookinfo" {
  source                     = "./modules/app/bookinfo"
  k8s_host                   = element(module.azure_k8s, var.cluster_id).host
  k8s_cluster_ca_certificate = element(module.azure_k8s, var.cluster_id).cluster_ca_certificate
  k8s_client_certificate     = element(module.azure_k8s, var.cluster_id).client_certificate
  k8s_client_key             = element(module.azure_k8s, var.cluster_id).client_key
}

/*
module "azure_oidc" {
  source      = "./modules/azure/oidc"
  name_prefix = var.name_prefix
  tctl_host   = module.tsb_mp.host
} 
*/
