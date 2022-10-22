data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${var.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

module "eshop" {
  source = "../../modules/apps/eshop"
  cluster_name               = data.terraform_remote_state.cluster.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.cluster.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.cluster.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.cluster.outputs.token
  eshop_host                 = var.eshop_host
  payments_host              = var.payments_host
  payments_latency_ms        = var.payments_latency_ms
  checkout_error_percentage  = var.checkout_error_percentage
  tenant_owner               = var.tenant_owner
  eshop_owner                = var.eshop_owner
  payments_owner             = var.payments_owner
}
