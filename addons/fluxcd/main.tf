data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud_provider}/terraform.tfstate.d/${var.cloud_provider}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud_provider}/k8s_auth/terraform.tfstate.d/${var.cloud_provider}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

module "fluxcd" {
  source                     = "../../modules/addons/fluxcd"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  applications               = var.fluxcd_include_example_applications ? "${path.module}/applications/*.yaml" : ""
}