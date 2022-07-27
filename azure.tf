provider "azurerm" {
  features {}
}

module "azure_base" {
  source         = "./modules/azure/base"
  count          = length(var.azure_k8s_regions)
  name_prefix    = "${var.name_prefix}-${count.index}-${var.azure_k8s_regions[count.index]}"
  location       = var.azure_k8s_regions[count.index]
  cidr           = cidrsubnet(var.cidr, 4, count.index)
  clusters_count = length(var.azure_k8s_regions)
}

module "azure_jumpbox" {
  source                  = "./modules/azure/jumpbox"
  count                   = length(var.azure_k8s_regions) > 0 ? 1 : 0
  name_prefix             = "${var.name_prefix}-${count.index}-${var.azure_k8s_regions[count.index]}"
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
  name_prefix         = "${var.name_prefix}-${count.index}-${var.azure_k8s_regions[count.index]}"
  cluster_name        = "${var.name_prefix}-aks-${count.index + 1}"
  vnet_subnet         = module.azure_base[count.index].vnet_subnets[count.index]
  registry_id         = module.azure_base[0].registry_id
  depends_on          = [module.azure_jumpbox[0]]
}
