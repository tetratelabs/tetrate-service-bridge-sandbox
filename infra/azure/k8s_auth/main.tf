provider "azurerm" {
  features {}

  #https://github.com/hashicorp/terraform-provider-azurerm/issues/13776
  /* default_tags {
    tags = local.default_tags
  } */
}

data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_region}/terraform.tfstate"
  }
}

module "azure_k8s_auth" {
  source              = "../../../modules/azure/k8s_auth"
  cluster_name        = data.terraform_remote_state.infra.outputs.cluster_name
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
}
