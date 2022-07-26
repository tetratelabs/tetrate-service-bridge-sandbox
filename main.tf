module "azure_base" {
  source         = "./modules/azure/base"
  count          = length(var.azure_k8s_regions)
  name_prefix    = var.name_prefix
  location       = var.azure_k8s_regions[count.index]
  cidr           = cidrsubnet(var.cidr, 4, count.index)
  clusters_count = length(var.azure_k8s_regions)
}

module "azure_jumpbox" {
  source                  = "./modules/azure/jumpbox"
  count                   = length(var.azure_k8s_regions) > 0 ? 1 : 0
  name_prefix             = var.name_prefix
  location                = var.azure_k8s_regions[0]
  resource_group_name     = module.azure_base[0].resource_group_name
  cidr                    = module.azure_base[0].cidr
  vnet_subnet             = module.azure_base[0].vnet_subnets[0]
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.azure_base[0].registry
  registry_username       = module.azure_base[0].registry_username
  registry_password       = module.azure_base[0].registry_password
}

module "azure_k8s" {
  source              = "./modules/azure/k8s"
  count               = length(var.azure_k8s_regions)
  k8s_version         = var.azure_aks_k8s_version
  resource_group_name = module.azure_base[0].resource_group_name
  location            = var.azure_k8s_regions[count.index]
  name_prefix         = var.name_prefix
  cluster_name        = "${var.name_prefix}-aks-${count.index + 1}"
  vnet_subnet         = module.azure_base[0].vnet_subnets[count.index]
  registry_id         = module.azure_base[0].registry_id
  depends_on          = [module.azure_jumpbox[0]]
}

module "aws_base" {
  source      = "./modules/aws/base"
  count       = length(var.aws_k8s_regions)
  name_prefix = var.name_prefix
  cidr        = cidrsubnet(var.cidr, 4, 16 + count.index)
}

module "aws_jumpbox" {
  source                  = "./modules/aws/jumpbox"
  count                   = length(var.aws_k8s_regions) > 0 ? 1 : 0
  owner                   = var.owner
  name_prefix             = var.name_prefix
  region                  = var.aws_k8s_regions[0]
  vpc_id                  = module.aws_base[0].vpc_id
  vpc_subnet              = module.aws_base[0].vpc_subnets[0]
  cidr                    = module.aws_base[0].cidr
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.aws_base[0].registry
}

module "aws_k8s" {
  source       = "./modules/aws/k8s"
  count        = length(var.aws_k8s_regions)
  owner        = var.owner
  k8s_version  = var.aws_eks_k8s_version
  region       = var.aws_k8s_regions[count.index]
  vpc_id       = module.aws_base[0].vpc_id
  vpc_subnets  = module.aws_base[0].vpc_subnets
  name_prefix  = var.name_prefix
  cluster_name = "${var.name_prefix}-eks-${count.index + 1}"
  depends_on   = [module.aws_jumpbox[0]]
}

module "gcp_base" {
  count       = length(var.gcp_k8s_regions)
  source      = "./modules/gcp/base"
  name_prefix = "${var.name_prefix}-${var.gcp_k8s_regions[count.index]}"
  project_id  = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region      = var.gcp_k8s_regions[count.index]
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = cidrsubnet(var.cidr, 4, 32 + count.index)
}

module "gcp_jumpbox" {
  count                   = length(var.gcp_k8s_regions) > 0 ? 1 : 0
  source                  = "./modules/gcp/jumpbox"
  name_prefix             = var.name_prefix
  region                  = var.gcp_k8s_regions[0]
  project_id              = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
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
  count        = length(var.gcp_k8s_regions)
  name_prefix  = "${var.name_prefix}-${var.gcp_k8s_regions[count.index]}"
  cluster_name = "${var.name_prefix}-gke-${count.index + 1}"
  project_id   = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region       = var.gcp_k8s_regions[count.index]
  k8s_version  = var.gcp_gke_k8s_version
  depends_on   = [module.gcp_jumpbox[0]]
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
  registry                   = local.base[var.tsb_mp["cloud"]].registry
  cluster_name               = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].cluster_name
  k8s_host                   = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].host
  k8s_cluster_ca_certificate = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.tsb_mp["cloud"]][var.tsb_mp["cluster_id"]].token
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
  tier1_cluster              = var.cluster_id == var.tsb_mp["cluster_id"] && var.cloud == var.tsb_mp["cloud"] ? var.mp_as_tier1_cluster : false
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
