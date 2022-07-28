data "terraform_remote_state" "aws" {
  count   = length(var.aws_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/aws/terraform.tfstate.d/aws-${count.index}-${var.aws_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "azure" {
  count   = length(var.azure_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/azure/terraform.tfstate.d/azure-${count.index}-${var.azure_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "gcp" {
  count   = length(var.gcp_k8s_regions)
  backend = "local"
  config = {
    path = "../../infra/gcp/terraform.tfstate.d/gcp-${count.index}-${var.gcp_k8s_regions[count.index]}/terraform.tfstate"
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
  cluster_name               = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_name
  k8s_host                   = local.infra[var.cloud][var.cluster_id]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.cloud][var.cluster_id]["outputs"].token
  cert-manager_enabled       = var.cert-manager_enabled
}

module "tsb_cp" {
  source                     = "../../modules/tsb/cp"
  cloud                      = var.cloud
  locality_region            = local.infra[var.cloud][var.cluster_id]["outputs"].locality_region
  cluster_id                 = var.cluster_id
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb_version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_mp_host                = data.terraform_remote_state.tsb_mp.outputs.fqdn
  tier1_cluster              = var.cluster_id == var.tsb_mp["cluster_id"] && var.cloud == var.tsb_mp["cloud"] ? var.mp_as_tier1_cluster : false
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_cacert                 = data.terraform_remote_state.tsb_mp.outputs.tsb_cacert
  istiod_cacerts_tls_crt     = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key     = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_key
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  output_path                = var.output_path
  es_host                    = data.terraform_remote_state.tsb_mp.outputs.es_ip != "" ? data.terraform_remote_state.tsb_mp.outputs.es_ip : data.terraform_remote_state.tsb_mp.outputs.es_hostname
  es_username                = data.terraform_remote_state.tsb_mp.outputs.es_username
  es_password                = data.terraform_remote_state.tsb_mp.outputs.es_password
  es_cacert                  = data.terraform_remote_state.tsb_mp.outputs.es_cacert
  jumpbox_host               = local.infra[var.cloud][var.cluster_id]["outputs"].public_ip
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = local.infra[var.cloud][var.cluster_id]["outputs"].pkey
  registry                   = local.infra[var.cloud][var.cluster_id]["outputs"].registry
  cluster_name               = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_name
  k8s_host                   = local.infra[var.cloud][var.cluster_id]["outputs"].host
  k8s_cluster_ca_certificate = local.infra[var.cloud][var.cluster_id]["outputs"].cluster_ca_certificate
  k8s_client_token           = local.infra[var.cloud][var.cluster_id]["outputs"].token
}
