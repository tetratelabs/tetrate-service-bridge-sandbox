data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${local.cluster.cloud}/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${local.cluster.cloud}/k8s_auth/terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

module "fluxcd" {
  source                     = "../../modules/addons/fluxcd"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  applications               = local.addon_config.include_example_apps ? "${path.module}/applications/*.yaml" : ""
}
