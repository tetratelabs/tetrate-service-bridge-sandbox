data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/azure/terraform.tfstate.d/azure-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/azure/k8s_auth/terraform.tfstate.d/azure-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../modules/addons/external-dns/azure"
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  kubelet_identity           = data.terraform_remote_state.infra.outputs.kubelet_identity 
  resource_group_name        = data.terraform_remote_state.infra.outputs.resource_group_name
  resource_group_id          = data.terraform_remote_state.infra.outputs.resource_group_id
  tags                       = local.tags
  dns_zone                   = var.external_dns_zone
  sources                    = var.external_dns_sources
  annotation_filter          = var.external_dns_annotation_filter
  label_filter               = var.external_dns_label_filter
  interval                   = var.external_dns_interval
  output_path                = var.output_path
}
