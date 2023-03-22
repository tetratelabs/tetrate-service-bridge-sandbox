provider "azurerm" {
  features {}

  #https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  /* default_tags {
    tags = local.default_tags
  } */
}

module "azure_base" {
  source      = "../../modules/azure/base"
  count       = var.azure_k8s_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.cluster_id}"
  location    = var.azure_k8s_region
  cidr        = cidrsubnet(var.cidr, 4, 0 + tonumber(var.cluster_id))
  tags        = local.default_tags 
}

module "azure_jumpbox" {
  source                    = "../../modules/azure/jumpbox"
  count                     = var.azure_k8s_region == null ? 0 : 1
  name_prefix               = "${var.name_prefix}-${var.cluster_id}"
  location                  = var.azure_k8s_region
  resource_group_name       = module.azure_base[0].resource_group_name
  cidr                      = module.azure_base[0].cidr
  vnet_subnet               = module.azure_base[0].vnet_subnets[0]
  tsb_version               = var.tsb_version
  tsb_helm_repository       = var.tsb_helm_repository
  jumpbox_username          = var.jumpbox_username
  tsb_image_sync_username   = var.tsb_image_sync_username
  tsb_image_sync_apikey     = var.tsb_image_sync_apikey
  registry                  = module.azure_base[0].registry
  registry_username         = module.azure_base[0].registry_username
  registry_password         = module.azure_base[0].registry_password
  output_path               = var.output_path
  tags                      = local.default_tags 
}

module "azure_k8s" {
  source              = "../../modules/azure/k8s"
  count               = var.azure_k8s_region == null ? 0 : 1
  k8s_version         = var.azure_aks_k8s_version
  resource_group_name = module.azure_base[0].resource_group_name
  location            = var.azure_k8s_region
  name_prefix         = "${var.name_prefix}-${var.cluster_id}"
  cluster_name        = coalesce(var.cluster_name, "aks-${var.azure_k8s_region}-${var.name_prefix}")
  vnet_subnet         = module.azure_base[0].vnet_subnets[0]
  registry_id         = module.azure_base[0].registry_id
  output_path         = var.output_path
  tags                = local.default_tags 
  depends_on          = [module.azure_jumpbox[0]]
}

module "azure_k8s_auth_token" {
  source              = "../../modules/azure/k8s_auth_token"
  count               = var.azure_k8s_region == null ? 0 : 1
  cluster_name        = module.azure_k8s[0].cluster_name
  resource_group_name = module.azure_base[0].resource_group_name
}