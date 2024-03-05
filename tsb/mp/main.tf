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
  es_version                 = local.tetrate.es_version
}

module "gatekeeper" {
  source                     = "../../modules/addons/gatekeeper"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  gatekeeper_enabled          = var.gatekeeper_enabled
}

module "tsb_mp" {
  source                       = "../../modules/tsb/mp"
  name_prefix                  = var.name_prefix
  tsb_version                  = local.tetrate.version
  tsb_helm_repository          = local.tetrate.helm_repository
  tsb_helm_repository_username = local.tetrate.helm_username
  tsb_helm_repository_password = local.tetrate.helm_password
  tsb_helm_version             = coalesce(local.tetrate.helm_version, local.tetrate.version)
  tsb_fqdn                     = local.tetrate.fqdn
  tsb_org                      = local.tetrate.organization
  tsb_username                 = local.tetrate.username
  tsb_password                 = local.tetrate.password
  tsb_image_sync_username      = local.tetrate.image_sync_username
  tsb_image_sync_apikey        = local.tetrate.image_sync_apikey
  es_host                      = coalesce(module.es.es_ip, module.es.es_hostname)
  es_username                  = module.es.es_username
  es_password                  = module.es.es_password
  es_cacert                    = module.es.es_cacert
  registry                     = data.terraform_remote_state.infra.outputs.registry
  cluster_name                 = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                     = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate   = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token             = data.terraform_remote_state.k8s_auth.outputs.token
}