module "azure_base" {
  source      = "../../modules/azure/base"
  name_prefix = "${var.name_prefix}-${local.cluster.index}"
  location    = local.cluster.region
  cidr        = cidrsubnet(var.cidr, 4, 0 + local.cluster.index)
  tags        = local.tags
}

module "azure_jumpbox" {
  source                  = "../../modules/azure/jumpbox"
  name_prefix             = "${var.name_prefix}-${local.cluster.index}"
  location                = local.cluster.region
  resource_group_name     = module.azure_base.resource_group_name
  cidr                    = module.azure_base.cidr
  vnet_subnet             = module.azure_base.vnet_subnets[0]
  tsb_version             = local.tetrate.version
  tsb_helm_repository     = local.tetrate.helm_repository
  jumpbox_username        = var.jumpbox_username
  machine_type            = var.jumpbox_machine_type
  tsb_image_sync_username = local.tetrate.image_sync_username
  tsb_image_sync_apikey   = local.tetrate.image_sync_apikey
  registry                = module.azure_base.registry
  registry_username       = module.azure_base.registry_username
  registry_password       = module.azure_base.registry_password
  output_path             = var.output_path
  tags                    = local.tags
}

module "azure_k8s" {
  source              = "../../modules/azure/k8s"
  k8s_version         = local.cluster.version
  instance_type       = local.cluster.instance_type
  resource_group_name = module.azure_base.resource_group_name
  location            = local.cluster.region
  name_prefix         = "${var.name_prefix}-${local.cluster.index}"
  cluster_name        = coalesce(local.cluster.name, "aks-${local.cluster.region}-${var.name_prefix}")
  vnet_subnet         = module.azure_base.vnet_subnets[0]
  registry_id         = module.azure_base.registry_id
  output_path         = var.output_path
  tags                = local.tags
  depends_on          = [module.azure_jumpbox]
}