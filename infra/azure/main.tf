provider "azurerm" {
  features {}

  #https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  /* default_tags {
    tags = local.default_tags
  } */
}

module "azure_base" {
  source      = "../../modules/azure/base"
  name_prefix = "${var.name_prefix}-${var.cluster_id}"
  location    = var.azure_k8s_region
  cidr        = cidrsubnet(var.cidr, 4, 0 + tonumber(var.cluster_id))
  tags        = local.default_tags
}

module "azure_jumpbox" {
  source                  = "../../modules/azure/jumpbox"
  name_prefix             = "${var.name_prefix}-${var.cluster_id}"
  location                = var.azure_k8s_region
  resource_group_name     = module.azure_base.resource_group_name
  cidr                    = module.azure_base.cidr
  vnet_subnet             = module.azure_base.vnet_subnets[0]
  tsb_version             = local.tsb.version
  tsb_image_sync_username = local.tsb.image_sync_username
  tsb_image_sync_apikey   = local.tsb.image_sync_apikey
  tsb_helm_repository     = local.tsb.helm_repository
  jumpbox_username        = var.jumpbox_username
  registry                = module.azure_base.registry
  registry_username       = module.azure_base.registry_username
  registry_password       = module.azure_base.registry_password
  output_path             = var.output_path
  tags                    = local.default_tags
}

module "azure_k8s" {
  source              = "../../modules/azure/k8s"
  k8s_version         = var.azure_aks_k8s_version
  resource_group_name = module.azure_base.resource_group_name
  location            = var.azure_k8s_region
  name_prefix         = "${var.name_prefix}-${var.cluster_id}"
  cluster_name        = coalesce(var.cluster_name, "aks-${var.azure_k8s_region}-${var.name_prefix}")
  vnet_subnet         = module.azure_base.vnet_subnets[0]
  registry_id         = module.azure_base.registry_id
  output_path         = var.output_path
  tags                = local.default_tags
  depends_on          = [module.azure_jumpbox]
}