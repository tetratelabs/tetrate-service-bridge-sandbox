data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../../modules/addons/gcp/external-dns"
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.infra.outputs.token
  project_id                 = data.terraform_remote_state.infra.outputs.project_id
  tags                       = local.default_tags
  dns_zone                   = var.external_dns_gcp_dns_zone
  sources                    = var.external_dns_sources
  annotation_filter          = var.external_dns_annotation_filter
  label_filter               = var.external_dns_label_filter
  interval                   = var.external_dns_interval
  output_path                = var.output_path
}