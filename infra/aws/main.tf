provider "aws" {
  region = var.aws_k8s_region

  # Re-enable this once https://github.com/hashicorp/terraform-provider-aws/issues/19583
  # is fixed. Until then, the workaround is to manually merge
  # the tags in every resource.
  # default_tags {
  #   tags = local.default_tags
  # }
}

resource "random_string" "random_id" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

module "aws_base" {
  source      = "../../modules/aws/base"
  count       = var.aws_k8s_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.cluster_id}-${random_string.random_id.result}"
  cidr        = cidrsubnet(var.cidr, 4, 4 + tonumber(var.cluster_id))
  tags        = local.default_tags
}

module "aws_jumpbox" {
  source                    = "../../modules/aws/jumpbox"
  count                     = var.aws_k8s_region == null ? 0 : 1
  name_prefix               = "${var.name_prefix}-${var.cluster_id}-${random_string.random_id.result}"
  region                    = var.aws_k8s_region
  vpc_id                    = module.aws_base[0].vpc_id
  vpc_subnet                = module.aws_base[0].vpc_subnets[0]
  cidr                      = module.aws_base[0].cidr
  tsb_version               = var.tsb_version
  tsb_helm_repository       = var.tsb_helm_repository
  jumpbox_username          = var.jumpbox_username
  tsb_image_sync_username   = var.tsb_image_sync_username
  tsb_image_sync_apikey     = var.tsb_image_sync_apikey
  registry                  = module.aws_base[0].registry
  registry_name             = module.aws_base[0].registry_name
  tags                      = local.default_tags
  output_path               = var.output_path
}

module "aws_k8s" {
  source       = "../../modules/aws/k8s"
  count        = var.aws_k8s_region == null ? 0 : 1
  k8s_version  = var.aws_eks_k8s_version
  region       = var.aws_k8s_region
  vpc_id       = module.aws_base[0].vpc_id
  vpc_subnets  = module.aws_base[0].vpc_subnets
  name_prefix  = "${var.name_prefix}-${var.cluster_id}-${random_string.random_id.result}"
  cluster_name = coalesce(var.cluster_name, "eks-${var.aws_k8s_region}-${var.name_prefix}")
  output_path  = var.output_path
  tags         = local.default_tags
  depends_on   = [module.aws_jumpbox[0]]
}

module "external_dns" {
  source                     = "../../modules/addons/aws/external-dns"
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  cluster_name               = module.aws_k8s[0].cluster_name
  k8s_host                   = module.aws_k8s[0].host
  k8s_cluster_ca_certificate = module.aws_k8s[0].cluster_ca_certificate
  k8s_client_token           = module.aws_k8s[0].token
  region                     = var.aws_k8s_region
  vpc_id                     = module.aws_base[0].vpc_id
  dns_zone                   = var.external_dns_aws_dns_zone
  sources                    = var.external_dns_sources
  annotation_filter          = var.external_dns_annotation_filter
  label_filter               = var.external_dns_label_filter
  interval                   = var.external_dns_interval
  tags                       = local.default_tags
  oidc_provider_arn          = module.aws_k8s[0].oidc_provider_arn
  cluster_oidc_issuer_url    = module.aws_k8s[0].cluster_oidc_issuer_url
  external_dns_enabled       = var.external_dns_enabled

}