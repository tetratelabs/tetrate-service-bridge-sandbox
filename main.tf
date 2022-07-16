module "azure_base" {
  source         = "./modules/azure/base"
  name_prefix    = var.name_prefix
  location       = var.azure_region
  cidr           = var.cidr
  clusters_count = 1 + var.azure_aks_app_clusters_count
}

module "azure_jumpbox" {
  source                  = "./modules/azure/jumpbox"
  name_prefix             = var.name_prefix
  location                = var.azure_region
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
  source              = "./modules/azure/k8s"
  count               = 1 + var.azure_aks_app_clusters_count
  k8s_version         = var.azure_aks_k8s_version
  resource_group_name = module.azure_base.resource_group_name
  location            = var.azure_region
  name_prefix         = var.name_prefix
  cluster_name        = "${var.name_prefix}-aks-${count.index + 1}"
  vnet_subnet         = module.azure_base.vnet_subnets[count.index]
  registry_id         = module.azure_base.registry_id
  depends_on          = [module.azure_jumpbox]
}

module "aws_base" {
  count       = var.aws_eks_app_clusters_count > 0 ? 1 : 0
  source      = "./modules/aws/base"
  name_prefix = var.name_prefix
  cidr        = var.cidr
}

module "aws_jumpbox" {
  source                  = "./modules/aws/jumpbox"
  count                   = var.aws_eks_app_clusters_count > 0 ? 1 : 0
  owner                   = var.owner
  name_prefix             = var.name_prefix
  vpc_id                  = module.aws_base[0].vpc_id
  vpc_subnet              = module.aws_base[0].vpc_subnets[0]
  cidr                    = var.cidr
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.aws_base[0].registry
}

module "aws_k8s" {
  source       = "./modules/aws/k8s"
  count        = var.aws_eks_app_clusters_count
  owner        = var.owner
  k8s_version  = var.aws_eks_k8s_version
  region       = var.aws_region
  vpc_id       = module.aws_base[0].vpc_id
  vpc_subnets  = module.aws_base[0].vpc_subnets
  name_prefix  = var.name_prefix
  cluster_name = "${var.name_prefix}-eks-${count.index + 1}"
  depends_on   = [module.aws_jumpbox[0]]
}

module "gcp_base" {
  count       = var.gcp_gke_app_clusters_count > 0 ? 1 : 0
  source      = "./modules/gcp/base"
  name_prefix = var.name_prefix
  region      = var.gcp_region
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = var.cidr
}

module "gcp_jumpbox" {
  count                   = var.gcp_gke_app_clusters_count > 0 ? 1 : 0
  source                  = "./modules/gcp/jumpbox"
  name_prefix             = var.name_prefix
  region                  = var.gcp_region
  project_id              = module.gcp_base[0].project_id
  vpc_id                  = module.gcp_base[0].vpc_id
  vpc_subnet              = module.gcp_base[0].vpc_subnets[0]
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.gcp_base[0].registry
}

module "gcp_k8s" {
  source       = "./modules/gcp/k8s"
  count        = var.gcp_gke_app_clusters_count
  name_prefix  = var.name_prefix
  cluster_name = "${var.name_prefix}-gke-${count.index + 1}"
  project_id   = module.gcp_base[0].project_id
  region       = var.gcp_region
  k8s_version  = var.gcp_gke_k8s_version
  depends_on   = [module.gcp_jumpbox[0]]
}

module "cert-manager" {
  source                     = "./modules/addons/cert-manager"
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
}

module "es" {
  source                     = "./modules/addons/elastic"
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
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


module "aws_route53_register_fqdn" {
  source   = "./modules/aws/route53_register_fqdn"
  dns_zone = var.dns_zone
  fqdn     = var.tsb_fqdn
  address  = module.tsb_mp.host
}

module "tsb_mp" {
  source = "./modules/tsb/mp"
  #source                     = "git::https://github.com/smarunich/terraform-tsb-mp.git?ref=v1.1.1"
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb_version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  registry                   = local.base["azure"].registry
  cluster_name               = local.cloud["azure"][0].cluster_name
  k8s_host                   = local.cloud["azure"][0].host
  k8s_cluster_ca_certificate = local.cloud["azure"][0].cluster_ca_certificate
  k8s_client_token           = local.cloud["azure"][0].token
}

module "tsb_cp" {
  source = "./modules/tsb/cp"
  #source                     = "git::https://github.com/smarunich/terraform-tsb-cp.git?ref=v1.1.1"
  cloud                      = var.cloud
  locality_region            = local.cloud[var.cloud][var.cluster_id].locality_region
  cluster_id                 = var.cluster_id
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb_version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_mp_host                = module.tsb_mp.host
  tier1_cluster              = var.cluster_id == "0" && var.cloud == "azure" ? var.mp_as_tier1_cluster : false
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_cacert                 = module.tsb_mp.tsb_cacert
  istiod_cacerts_tls_crt     = module.tsb_mp.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key     = module.tsb_mp.istiod_cacerts_tls_key
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  es_host                    = module.tsb_mp.es_host
  es_username                = module.tsb_mp.es_username
  es_password                = module.tsb_mp.es_password
  es_cacert                  = module.tsb_mp.es_cacert
  jumpbox_host               = local.jumpbox[var.cloud].public_ip
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = local.jumpbox[var.cloud].pkey
  registry                   = local.base[var.cloud].registry
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
}


module "app_bookinfo" {
  source                     = "./modules/app/bookinfo"
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
}

/*
module "azure_oidc" {
  source      = "./modules/azure/oidc"
  name_prefix = var.name_prefix
  tctl_host   = module.tsb_mp.host
} 
*/
