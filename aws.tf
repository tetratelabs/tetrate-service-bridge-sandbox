provider "aws" {
  default_tags {
    tags = local.aws_tags
  }
  region = var.aws_k8s_region
}

module "aws_base" {
  source      = "./modules/aws/base"
  count       = var.aws_k8s_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.aws_k8s_region}"
  cidr        = cidrsubnet(var.cidr, 4, 4)
}

module "aws_jumpbox" {
  source                  = "./modules/aws/jumpbox"
  count                   = var.aws_k8s_region == null ? 0 : 1
  owner                   = var.owner
  name_prefix             = "${var.name_prefix}-${var.aws_k8s_region}"
  region                  = var.aws_k8s_region
  vpc_id                  = module.aws_base[0].vpc_id
  vpc_subnet              = module.aws_base[0].vpc_subnets[0]
  cidr                    = module.aws_base[0].cidr
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.aws_base[0].registry
}

module "aws_k8s" {
  source       = "./modules/aws/k8s"
  count        = var.aws_k8s_region == null ? 0 : 1
  owner        = var.owner
  k8s_version  = var.aws_eks_k8s_version
  region       = var.aws_k8s_region
  vpc_id       = module.aws_base[0].vpc_id
  vpc_subnets  = module.aws_base[0].vpc_subnets
  name_prefix  = "${var.name_prefix}-${var.aws_k8s_region}"
  cluster_name = "${var.name_prefix}-eks-${count.index + 1}"
  depends_on   = [module.aws_jumpbox[0]]
}

module "aws_route53_register_fqdn" {
  source   = "./modules/aws/route53_register_fqdn"
  dns_zone = var.dns_zone
  fqdn     = var.tsb_fqdn
  address  = module.tsb_mp.host
}
