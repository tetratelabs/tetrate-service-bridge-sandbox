
data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "k8s_auth" {
  backend = "local"
  config = {
    path = "../../infra/${var.cloud}/k8s_auth/terraform.tfstate.d/${var.cloud}-${var.cluster_id}-${local.k8s_regions[var.cluster_id]}/terraform.tfstate"
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
  cert-manager_enabled       = tonumber(var.cluster_id) == tonumber(var.tsb_mp["cluster_id"]) && var.cloud == var.tsb_mp["cloud"] ? false : var.cert-manager_enabled
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
  source                          = "../../modules/tsb/cp"
  cloud                           = var.cloud
  locality_region                 = data.terraform_remote_state.infra.outputs.locality_region
  cluster_id                      = var.cluster_id
  name_prefix                     = "${var.name_prefix}-${var.cluster_id}"
  tsb_version                     = var.tsb_version
  tsb_helm_repository             = var.tsb_helm_repository
  tsb_helm_repository_username    = var.tsb_helm_repository_username
  tsb_helm_repository_password    = var.tsb_helm_repository_password
  tsb_helm_version                = coalesce(var.tsb_helm_version, var.tsb_version)
  tsb_mp_host                     = data.terraform_remote_state.tsb_mp.outputs.fqdn
  tier1_cluster                   = tonumber(var.cluster_id) == tonumber(var.tsb_mp["cluster_id"]) && var.cloud == var.tsb_mp["cloud"] ? var.mp_as_tier1_cluster : false
  tsb_fqdn                        = var.tsb_fqdn
  tsb_org                         = var.tsb_org
  tsb_username                    = var.tsb_username
  tsb_password                    = data.terraform_remote_state.tsb_mp.outputs.tsb_password
  tsb_cacert                      = data.terraform_remote_state.tsb_mp.outputs.tsb_cacert
  ratelimit_enabled               = var.ratelimit_enabled
  ratelimit_namespace             = module.ratelimit.namespace
  redis_password                  = module.ratelimit.redis_password
  identity_propagation_enabled    = var.identity_propagation_enabled
  istiod_cacerts_tls_crt          = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key          = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_key
  tsb_image_sync_username         = var.tsb_image_sync_username
  tsb_image_sync_apikey           = var.tsb_image_sync_apikey
  output_path                     = var.output_path
  es_host                         = coalesce(data.terraform_remote_state.tsb_mp.outputs.es_ip, data.terraform_remote_state.tsb_mp.outputs.es_hostname)
  es_username                     = data.terraform_remote_state.tsb_mp.outputs.es_username
  es_password                     = data.terraform_remote_state.tsb_mp.outputs.es_password
  es_cacert                       = data.terraform_remote_state.tsb_mp.outputs.es_cacert
  jumpbox_host                    = data.terraform_remote_state.infra.outputs.public_ip
  jumpbox_username                = var.jumpbox_username
  jumpbox_pkey                    = data.terraform_remote_state.infra.outputs.pkey
  registry                        = data.terraform_remote_state.infra.outputs.registry
  registry_username               = data.terraform_remote_state.infra.outputs.registry_username
  registry_password               = data.terraform_remote_state.infra.outputs.registry_password
  cluster_name                    = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                        = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate      = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token                = data.terraform_remote_state.k8s_auth.outputs.token
}
