data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_region}/terraform.tfstate"
  }
}

module "aws_k8s_auth" {
  source       = "../../../modules/aws/k8s_auth"
  cluster_name = data.terraform_remote_state.infra.outputs.cluster_name
}
