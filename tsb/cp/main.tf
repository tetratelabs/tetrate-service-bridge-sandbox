data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud_provider}/terraform.tfstate.d/${var.cloud_provider}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud_provider}/k8s_auth/terraform.tfstate.d/${var.cloud_provider}-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tsb_mp" {
  backend = "local"
  config = {
    path = "../mp/terraform.tfstate"
  }
}

module "cert-manager" {
  source                     = "../../modules/addons/cert-manager"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.k8s_auth.outputs.token
  cert_manager_enabled       = tonumber(var.cluster_id) == 0 && var.mp_cluster.tier1 ? false : var.cert_manager_enabled
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
  cloud                        = var.cloud_provider
  cluster_id                   = var.cluster_id
  cluster_name                 = data.terraform_remote_state.infra.outputs.cluster_name
  es_cacert                    = data.terraform_remote_state.tsb_mp.outputs.es_cacert
  es_host                      = coalesce(data.terraform_remote_state.tsb_mp.outputs.es_ip, data.terraform_remote_state.tsb_mp.outputs.es_hostname)
  es_password                  = data.terraform_remote_state.tsb_mp.outputs.es_password
  es_username                  = data.terraform_remote_state.tsb_mp.outputs.es_username
  identity_propagation_enabled = var.identity_propagation_enabled
  istiod_cacerts_tls_crt       = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key       = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_key
  jumpbox_host                 = data.terraform_remote_state.infra.outputs.public_ip
  jumpbox_pkey                 = data.terraform_remote_state.infra.outputs.pkey
  jumpbox_username             = var.jumpbox_username
  k8s_client_token             = data.terraform_remote_state.k8s_auth.outputs.token
  k8s_cluster_ca_certificate   = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_host                     = data.terraform_remote_state.infra.outputs.host
  locality_region              = data.terraform_remote_state.infra.outputs.locality_region
  name_prefix                  = "${var.name_prefix}-${var.cluster_id}"
  output_path                  = var.output_path
  ratelimit_enabled            = var.ratelimit_enabled
  ratelimit_namespace          = module.ratelimit.namespace
  redis_password               = module.ratelimit.redis_password
  registry                     = data.terraform_remote_state.infra.outputs.registry
  registry_password            = data.terraform_remote_state.infra.outputs.registry_password
  registry_username            = data.terraform_remote_state.infra.outputs.registry_username
  tier1_cluster                = tonumber(var.cluster_id) == 0 && var.mp_cluster.tier1
  tsb_cacert                   = data.terraform_remote_state.tsb_mp.outputs.tsb_cacert
  tsb_fqdn                     = local.tsb.fqdn
  tsb_helm_repository          = local.tsb.helm_repository
  tsb_helm_repository_password = local.tsb.helm_repository_password
  tsb_helm_repository_username = local.tsb.helm_repository_username
  tsb_helm_version             = coalesce(local.tsb.helm_version, local.tsb.version)
  tsb_image_sync_apikey        = local.tsb.image_sync_apikey
  tsb_image_sync_username      = local.tsb.image_sync_username
  tsb_mp_host                  = data.terraform_remote_state.tsb_mp.outputs.fqdn
  tsb_org                      = local.tsb.organisation
  tsb_password                 = data.terraform_remote_state.tsb_mp.outputs.tsb_password
  tsb_username                 = local.tsb.username
  tsb_version                  = local.tsb.version
}
