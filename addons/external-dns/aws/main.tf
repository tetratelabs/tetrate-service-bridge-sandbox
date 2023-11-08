data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/${local.cluster.cloud}/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../../infra/${local.cluster.cloud}/k8s_auth/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../../modules/addons/aws/external-dns"
  name_prefix                = "${var.name_prefix}-${local.cluster.index}"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  oidc_provider_arn          = data.terraform_remote_state.infra.outputs.oidc_provider_arn
  cluster_oidc_issuer_url    = data.terraform_remote_state.infra.outputs.cluster_oidc_issuer_url
  vpc_id                     = data.terraform_remote_state.infra.outputs.vpc_id
  region                     = local.cluster.region
  tags                       = local.tags
  dns_zone                   = local.addon_config.dns_zone
  sources                    = local.addon_config.dns_sources
  annotation_filter          = local.addon_config.dns_annotation_filter
  label_filter               = local.addon_config.dns_label_filter
  interval                   = local.addon_config.dns_interval
  output_path                = var.output_path
}