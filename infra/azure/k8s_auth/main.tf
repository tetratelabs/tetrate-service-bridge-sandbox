data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../terraform.tfstate.d/${local.cluster.workspace}/terraform.tfstate"
  }
}

module "azure_k8s_auth" {
  source              = "../../../modules/azure/k8s_auth"
  cluster_name        = data.terraform_remote_state.infra.outputs.cluster_name
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
}
