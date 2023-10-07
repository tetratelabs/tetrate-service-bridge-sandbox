provider "google" {
  /* https://github.com/hashicorp/terraform-provider-google/issues/7325
  default_labels = {
  } */
}

resource "random_string" "random_prefix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  count           = var.gcp_project_id == null ? 1 : 0
  name            = "${var.name_prefix}-${random_string.random_prefix.result}-${var.cluster_id}"
  project_id      = "${var.name_prefix}-${random_string.random_prefix.result}-${var.cluster_id}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id

  labels = merge(local.default_tags, {
    name = "${var.name_prefix}_project"
  })
}

module "gcp_base" {
  source      = "../../modules/gcp/base"
  name_prefix = "${var.name_prefix}-${var.cluster_id}"
  project_id  = coalesce(google_project.tsb[0].project_id, var.gcp_project_id)
  region      = var.gcp_k8s_region
  cidr        = cidrsubnet(var.cidr, 4, 8 + tonumber(var.cluster_id))
}

module "gcp_jumpbox" {
  source                  = "../../modules/gcp/jumpbox"
  name_prefix             = "${var.name_prefix}-${var.cluster_id}"
  region                  = var.gcp_k8s_region
  project_id              = coalesce(var.gcp_project_id, google_project.tsb[0].project_id)
  vpc_id                  = module.gcp_base.vpc_id
  vpc_subnet              = module.gcp_base.vpc_subnets[0]
  tsb_version             = local.tsb.version
  tsb_image_sync_username = local.tsb.image_sync_username
  tsb_image_sync_apikey   = local.tsb.image_sync_apikey
  tsb_helm_repository     = local.tsb.helm_repository
  jumpbox_username        = var.jumpbox_username
  machine_type            = var.jumpbox_machine_type
  registry                = module.gcp_base.registry
  output_path             = var.output_path
  tags                    = local.default_tags
}

module "gcp_k8s" {
  source            = "../../modules/gcp/k8s"
  name_prefix       = "${var.name_prefix}-${var.cluster_id}"
  cluster_name      = coalesce(var.cluster_name, "gke-${var.gcp_k8s_region}-${var.name_prefix}")
  project_id        = coalesce(var.gcp_project_id, google_project.tsb[0].project_id)
  vpc_id            = module.gcp_base.vpc_id
  vpc_subnet        = module.gcp_base.vpc_subnets[0]
  region            = var.gcp_k8s_region
  preemptible_nodes = var.preemptible_nodes
  k8s_version       = var.gcp_gke_k8s_version
  output_path       = var.output_path
  tags              = local.default_tags
  depends_on        = [module.gcp_jumpbox]
}

