data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../terraform.tfstate.d/aws-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

module "aws_k8s_auth" {
  source       = "../../../modules/aws/k8s_auth"
  cluster_name = data.terraform_remote_state.infra.outputs.cluster_name
}
