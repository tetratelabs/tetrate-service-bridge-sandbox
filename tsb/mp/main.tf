data "terraform_remote_state" "infra" {
  count   = length(local.k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/${var.tsb_mp["cloud"]}/terraform.tfstate.d/${var.tsb_mp["cloud"]}-${count.index}-${local.k8s_regions[count.index]}/terraform.tfstate"
  }
}

module "cert-manager" {
  source                     = "../../modules/addons/cert-manager"
  cluster_name               = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_name
  k8s_host                   = local.infra[var.tsb_mp["cluster_id"]]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.tsb_mp["cluster_id"]]["outputs"].token
  cert-manager_enabled       = var.cert-manager_enabled
}

module "es" {
  source                     = "../../modules/addons/elastic"
  cluster_name               = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_name
  k8s_host                   = local.infra[var.tsb_mp["cluster_id"]]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.tsb_mp["cluster_id"]]["outputs"].token
}

module "tsb_mp" {
  source                     = "../../modules/tsb/mp"
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb_version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  es_host                    = coalesce(module.es.es_ip, module.es.es_hostname)
  es_username                = module.es.es_username
  es_password                = module.es.es_password
  es_cacert                  = module.es.es_cacert
  registry                   = local.infra[var.tsb_mp["cluster_id"]]["outputs"].registry
  cluster_name               = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_name
  k8s_host                   = local.infra[var.tsb_mp["cluster_id"]]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.tsb_mp["cluster_id"]]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.tsb_mp["cluster_id"]]["outputs"].token
}
