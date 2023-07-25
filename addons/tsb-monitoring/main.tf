data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.tsb_mp["cloud"]}/terraform.tfstate.d/${var.tsb_mp["cloud"]}-${var.tsb_mp["cluster_id"]}-${local.k8s_regions[tonumber(var.tsb_mp["cluster_id"])]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${var.tsb_mp["cloud"]}/k8s_auth/terraform.tfstate.d/${var.tsb_mp["cloud"]}-${var.tsb_mp["cluster_id"]}-${local.k8s_regions[tonumber(var.tsb_mp["cluster_id"])]}/terraform.tfstate"
  }
}

module "prometheus" {
  source                     = "../../modules/addons/tsb-prometheus"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  namespace                  = var.monitoring_namespace
}

module "grafana" {
  source                     = "../../modules/addons/tsb-grafana"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  namespace                  = var.monitoring_namespace
  service_type               = var.grafana_service_type
  password                   = var.tsb_password
  
  dashboards = {for d in fileset("${path.module}/dashboards", "*.json") : d => file("${path.module}/dashboards/${d}")}
}
