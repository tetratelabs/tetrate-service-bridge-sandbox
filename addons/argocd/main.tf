data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

module "argocd" {
  source                     = "../../modules/addons/argocd"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.infra.outputs.token
  password                   = var.tsb_password

  applications = {for a in fileset("${path.module}/applications", "*.yaml") : a => file("${path.module}/applications/${a}")}
}
