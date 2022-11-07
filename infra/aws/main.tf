provider "aws" {
  region = var.aws_k8s_region
}

module "aws_base" {
  source      = "../../modules/aws/base"
  count       = var.aws_k8s_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.cluster_id}"
  cidr        = cidrsubnet(var.cidr, 4, 4 + tonumber(var.cluster_id))
  owner       = "${var.tsb_image_sync_username}@tetrate.io"
}

module "aws_jumpbox" {
  source                    = "../../modules/aws/jumpbox"
  count                     = var.aws_k8s_region == null ? 0 : 1
  owner                     = "${var.tsb_image_sync_username}@tetrate.io"
  name_prefix               = "${var.name_prefix}-${var.cluster_id}"
  region                    = var.aws_k8s_region
  vpc_id                    = module.aws_base[0].vpc_id
  vpc_subnet                = module.aws_base[0].vpc_subnets[0]
  cidr                      = module.aws_base[0].cidr
  tsb_version               = var.tsb_version
  jumpbox_username          = var.jumpbox_username
  tsb_image_sync_username   = var.tsb_image_sync_username
  tsb_image_sync_apikey     = var.tsb_image_sync_apikey
  registry                  = module.aws_base[0].registry
  output_path               = var.output_path
}

module "aws_k8s" {
  source       = "../../modules/aws/k8s"
  count        = var.aws_k8s_region == null ? 0 : 1
  owner        = "${var.tsb_image_sync_username}@tetrate.io"
  k8s_version  = var.aws_eks_k8s_version
  region       = var.aws_k8s_region
  vpc_id       = module.aws_base[0].vpc_id
  vpc_subnets  = module.aws_base[0].vpc_subnets
  name_prefix  = "${var.name_prefix}-${var.cluster_id}"
  cluster_name = var.cluster_name == null ? "eks-${var.aws_k8s_region}-${var.name_prefix}" : var.cluster_name
  output_path  = var.output_path
  depends_on   = [module.aws_jumpbox[0]]
}
