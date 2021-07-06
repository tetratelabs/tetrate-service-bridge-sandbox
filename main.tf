module "azure_base" {
  source      = "./modules/azure/base"
  name_prefix = var.name_prefix
  location    = var.location
  cidr        = var.cidr
}

module "azure_jumpbox" {
  source                 = "./modules/azure/jumpbox"
  name_prefix            = var.name_prefix
  location               = var.location
  resource_group_name    = module.azure_base.resource_group_name
  cidr                   = var.cidr
  vnet_subnets           = module.azure_base.vnet_subnets
  tsb_version            = var.tsb_version
  jumpbox_username       = var.jumpbox_username
  image-sync_username    = var.image-sync_username
  image-sync_apikey      = var.image-sync_apikey
  registry               = module.azure_base.registry
  registry_username      = module.azure_base.registry_username
  registry_password      = module.azure_base.registry_password
  depends_on             = [ module.azure_base ]   
}

module "azure_k8s" {
  count                  = 1 + var.cp_count
  source                 = "./modules/azure/k8s"
  resource_group_name    = module.azure_base.resource_group_name
  location               = var.location
  name_prefix            = var.name_prefix
  cluster_name           = "${var.name_prefix}-aks-${count.index+1}"
  vnet_subnets           = module.azure_base.vnet_subnets
  registry_id            = module.azure_base.registry_id
  depends_on             = [ module.azure_base, module.azure_jumpbox ]   
}

module "elastic" {
  source                      = "./modules/azure/elastic"
  k8s_host                    = module.azure_k8s.0.host
  k8s_cluster_ca_certificate  = module.azure_k8s.0.cluster_ca_certificate
  k8s_client_certificate      = module.azure_k8s.0.client_certificate
  k8s_client_key              = module.azure_k8s.0.client_key
}

module "tsb_mp" {
  source                      = "./modules/tsb/mp"
  cluster_name                = module.azure_k8s.0.cluster_name
  tctl_username               = var.tctl_username
  tctl_password               = var.tctl_password
  k8s_host                    = module.azure_k8s.0.host
  k8s_cluster_ca_certificate  = module.azure_k8s.0.cluster_ca_certificate
  k8s_client_certificate      = module.azure_k8s.0.client_certificate
  k8s_client_key              = module.azure_k8s.0.client_key
  registry                    = module.azure_base.registry
}

module "tsb_cp" {
  source                      = "./modules/tsb/cp"
  tctl_host                   = module.tsb_mp.host
  tctl_username               = var.tctl_username
  tctl_password               = var.tctl_password
  es_host                     = module.tsb_mp.es_host
  es_password                 = module.tsb_mp.es_password
  es_cacert                   = module.tsb_mp.es_cacert
  cluster_name                = module.azure_k8s.1.cluster_name
  k8s_host                    = module.azure_k8s.1.host
  k8s_cluster_ca_certificate  = module.azure_k8s.1.cluster_ca_certificate
  k8s_client_certificate      = module.azure_k8s.1.client_certificate
  k8s_client_key              = module.azure_k8s.1.client_key
  registry                    = module.azure_base.registry
}

