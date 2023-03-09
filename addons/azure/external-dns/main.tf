data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  #https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  /* default_tags {
    tags = local.default_tags
  } */
}

module "external_dns" {
  source                     = "../../../modules/addons/azure/external-dns"
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.infra.outputs.token
  kubelet_identity           = data.terraform_remote_state.infra.outputs.kubelet_identity 
  resource_group_name        = data.terraform_remote_state.infra.outputs.resource_group_name
  resource_group_id          = data.terraform_remote_state.infra.outputs.resource_group_id
  tags                       = local.default_tags
  dns_zone                   = var.external_dns_azure_dns_zone
  sources                    = var.external_dns_sources
  annotation_filter          = var.external_dns_annotation_filter
  label_filter               = var.external_dns_label_filter
  interval                   = var.external_dns_interval
  output_path                = var.output_path
}