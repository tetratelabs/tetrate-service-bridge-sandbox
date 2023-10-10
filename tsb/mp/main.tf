data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/k8s_auth/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

module "cert-manager" {
  source                     = "../../modules/addons/cert-manager"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  cert-manager_enabled       = var.cert-manager_enabled
}

module "es" {
  source                     = "../../modules/addons/elastic"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
}

module "tsb_mp" {
  source                          = "../../modules/tsb/mp"
  cluster_name                    = data.terraform_remote_state.infra.outputs.cluster_name
  es_cacert                       = module.es.es_cacert
  es_host                         = coalesce(module.es.es_ip, module.es.es_hostname)
  es_password                     = module.es.es_password
  es_username                     = module.es.es_username
  k8s_client_token                = data.terraform_remote_state.k8s_auth.outputs.token
  k8s_cluster_ca_certificate      = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_host                        = data.terraform_remote_state.infra.outputs.host
  name_prefix                     = var.name_prefix
  registry                        = data.terraform_remote_state.infra.outputs.registry
  tsb_fqdn                        = var.tsb.fqdn
  tsb_helm_repository             = var.tsb.helm_repository
  tsb_helm_repository_password    = var.tsb.helm_repository_password
  tsb_helm_repository_username    = var.tsb.helm_repository_username
  tsb_helm_version                = coalesce(var.tsb.helm_version, var.tsb.version)
  tsb_image_sync_apikey           = var.tsb.image_sync_apikey
  tsb_image_sync_username         = var.tsb.image_sync_username
  tsb_org                         = var.tsb.organisation
  tsb_password                    = var.tsb.password
  tsb_username                    = var.tsb.username
  tsb_version                     = var.tsb.version
}
