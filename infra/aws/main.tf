resource "random_string" "random_id" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

module "aws_base" {
  source      = "../../modules/aws/base"
  name_prefix = "${var.name_prefix}-${local.cluster.index}-${random_string.random_id.result}"
  cidr        = cidrsubnet(var.cidr, 4, 4 + local.cluster.index)
  tags        = local.tags
  output_path = var.output_path
}

module "aws_jumpbox" {
  source                  = "../../modules/aws/jumpbox"
  name_prefix             = "${var.name_prefix}-${local.cluster.index}-${random_string.random_id.result}"
  region                  = local.cluster.region
  vpc_id                  = module.aws_base.vpc_id
  vpc_subnet              = module.aws_base.vpc_subnets[0]
  cidr                    = module.aws_base.cidr
  tsb_version             = local.tetrate.version
  tsb_helm_repository     = local.tetrate.helm_repository
  jumpbox_username        = var.jumpbox_username
  machine_type            = var.jumpbox_machine_type
  tsb_image_sync_username = local.tetrate.image_sync_username
  tsb_image_sync_apikey   = local.tetrate.image_sync_apikey
  registry                = module.aws_base.registry
  registry_name           = module.aws_base.registry_name
  tags                    = local.tags
  output_path             = var.output_path
}

module "aws_k8s" {
  source               = "../../modules/aws/k8s"
  k8s_version          = local.cluster.version
  instance_type        = local.cluster.instance_type
  region               = local.cluster.region
  vpc_id               = module.aws_base.vpc_id
  vpc_subnets          = module.aws_base.vpc_subnets
  name_prefix          = "${var.name_prefix}-${local.cluster.index}-${random_string.random_id.result}"
  cluster_name         = coalesce(local.cluster.name, "eks-${local.cluster.region}-${var.name_prefix}")
  jumpbox_iam_role_arn = module.aws_jumpbox.jumpbox_iam_role_arn
  output_path          = var.output_path
  tags                 = local.tags
}