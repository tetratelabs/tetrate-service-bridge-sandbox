data "terraform_remote_state" "aws" {
  count = length(aws_k8s_regions)
  config = {
    path = "../infra/aws/terraform.tfstate.d/aws-${count.index}-${var.aws_k8s_regions[count.index]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "tsb_mp" {
  config = {
    path = "../tsb/mp/terraform.tfstate"
  }
}

module "tsb_cp" {
  source = "./modules/tsb/cp"
  #source                     = "git::https://github.com/smarunich/terraform-tsb-cp.git?ref=v1.1.1"
  cloud                      = var.cloud
  locality_region            = local.cloud[var.cloud][var.cluster_id].locality_region
  cluster_id                 = var.cluster_id
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb_version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb_helm_version != null ? var.tsb_helm_version : var.tsb_version
  tsb_mp_host                = module.tsb_mp.host
  tier1_cluster              = var.cluster_id == var.tsb_mp["cluster_id"] && var.cloud == var.tsb_mp["cloud"] ? var.mp_as_tier1_cluster : false
  tsb_fqdn                   = var.tsb_fqdn
  tsb_org                    = var.tsb_org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb_password
  tsb_cacert                 = module.tsb_mp.tsb_cacert
  istiod_cacerts_tls_crt     = module.tsb_mp.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key     = module.tsb_mp.istiod_cacerts_tls_key
  tsb_image_sync_username    = var.tsb_image_sync_username
  tsb_image_sync_apikey      = var.tsb_image_sync_apikey
  es_host                    = module.tsb_mp.es_host
  es_username                = module.tsb_mp.es_username
  es_password                = module.tsb_mp.es_password
  es_cacert                  = module.tsb_mp.es_cacert
  jumpbox_host               = local.jumpbox[var.cloud].public_ip
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = local.jumpbox[var.cloud].pkey
  registry                   = local.base[var.cloud].registry
  cluster_name               = local.cloud[var.cloud][var.cluster_id].cluster_name
  k8s_host                   = local.cloud[var.cloud][var.cluster_id].host
  k8s_cluster_ca_certificate = local.cloud[var.cloud][var.cluster_id].cluster_ca_certificate
  k8s_client_token           = local.cloud[var.cloud][var.cluster_id].token
}

module "aws_route53_register_fqdn" {
  source   = "../../modules/aws/route53_register_fqdn"
  dns_zone = var.dns_zone
  fqdn     = var.tsb_fqdn
  address  = module.tsb_mp.host
}
