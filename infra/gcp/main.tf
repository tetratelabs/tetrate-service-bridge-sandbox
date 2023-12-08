resource "random_string" "random_prefix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  count           = var.gcp_project_id == null ? 1 : 0
  name            = "${var.name_prefix}-${random_string.random_prefix.result}-${local.cluster.index}"
  project_id      = "${var.name_prefix}-${random_string.random_prefix.result}-${local.cluster.index}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id

  labels = merge(local.tags, {
    name = "${var.name_prefix}_project"
  })
}

module "gcp_base" {
  source      = "../../modules/gcp/base"
  name_prefix = "${var.name_prefix}-${local.cluster.index}"
  project_id  = coalesce(google_project.tsb[0].project_id, var.gcp_project_id)
  region      = local.cluster.region
  cidr        = cidrsubnet(var.cidr, 4, 8 + local.cluster.index)
}

module "gcp_jumpbox" {
  source                  = "../../modules/gcp/jumpbox"
  name_prefix             = "${var.name_prefix}-${local.cluster.index}"
  region                  = local.cluster.region
  project_id              = coalesce(var.gcp_project_id, google_project.tsb[0].project_id)
  vpc_id                  = module.gcp_base.vpc_id
  vpc_subnet              = module.gcp_base.vpc_subnets[0]
  tsb_version             = local.tetrate.version
  tsb_helm_repository     = local.tetrate.helm_repository
  jumpbox_username        = var.jumpbox_username
  machine_type            = var.jumpbox_machine_type
  tsb_image_sync_username = local.tetrate.image_sync_username
  tsb_image_sync_apikey   = local.tetrate.image_sync_apikey
  registry                = module.gcp_base.registry
  output_path             = var.output_path
  tags                    = local.tags
}

module "gcp_k8s" {
  source            = "../../modules/gcp/k8s"
  name_prefix       = "${var.name_prefix}-${local.cluster.index}"
  cluster_name      = coalesce(local.cluster.name, "gke-${local.cluster.region}-${var.name_prefix}")
  project_id        = coalesce(var.gcp_project_id, google_project.tsb[0].project_id)
  vpc_id            = module.gcp_base.vpc_id
  vpc_subnet        = module.gcp_base.vpc_subnets[0]
  region            = local.cluster.region
  preemptible_nodes = var.preemptible_nodes
  k8s_version       = local.cluster.version
  instance_type     = local.cluster.instance_type
  output_path       = var.output_path
  tags              = local.tags
  depends_on        = [module.gcp_jumpbox]
}

