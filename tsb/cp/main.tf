
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

data "terraform_remote_state" "tsb_mp" {
  backend = "local"
  config = {
    path = "../mp/terraform.tfstate.d/${var.name_prefix}/terraform.tfstate"
  }
}

module "ratelimit" {
  source                     = "../../modules/addons/ratelimit"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  enabled                    = var.ratelimit_enabled
}

module "tsb_cp" {
  source                       = "../../modules/tsb/cp"
  cloud                        = local.cluster.cloud
  locality_region              = data.terraform_remote_state.infra.outputs.locality_region
  cluster_id                   = local.cluster.index
  name_prefix                  = "${var.name_prefix}-${local.cluster.index}"
  tsb_version                  = local.tetrate.version
  tsb_helm_repository          = local.tetrate.helm_repository
  tsb_helm_repository_username = local.tetrate.helm_username
  tsb_helm_repository_password = local.tetrate.helm_password
  tsb_helm_version             = coalesce(local.tetrate.helm_version, local.tetrate.version)
  tsb_mp_host                  = data.terraform_remote_state.tsb_mp.outputs.fqdn
  tsb_fqdn                     = local.tetrate.fqdn
  tsb_org                      = local.tetrate.organization
  tsb_username                 = local.tetrate.username
  tsb_password                 = data.terraform_remote_state.tsb_mp.outputs.tsb_password
  tsb_cacert                   = data.terraform_remote_state.tsb_mp.outputs.tsb_cacert
  ratelimit_enabled            = var.ratelimit_enabled
  ratelimit_namespace          = module.ratelimit.namespace
  redis_password               = module.ratelimit.redis_password
  identity_propagation_enabled = var.identity_propagation_enabled
  tsb_image_sync_username      = local.tetrate.image_sync_username
  tsb_image_sync_apikey        = local.tetrate.image_sync_apikey
  output_path                  = var.output_path
  es_host                      = coalesce(data.terraform_remote_state.tsb_mp.outputs.es_ip, data.terraform_remote_state.tsb_mp.outputs.es_hostname)
  es_username                  = data.terraform_remote_state.tsb_mp.outputs.es_username
  es_password                  = data.terraform_remote_state.tsb_mp.outputs.es_password
  es_cacert                    = data.terraform_remote_state.tsb_mp.outputs.es_cacert
  jumpbox_host                 = data.terraform_remote_state.infra.outputs.public_ip
  jumpbox_username             = var.jumpbox_username
  jumpbox_pkey                 = data.terraform_remote_state.infra.outputs.pkey
  registry                     = data.terraform_remote_state.infra.outputs.registry
  registry_username            = data.terraform_remote_state.infra.outputs.registry_username
  registry_password            = data.terraform_remote_state.infra.outputs.registry_password
  cluster_name                 = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                     = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate   = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token             = data.terraform_remote_state.k8s_auth.outputs.token
}
