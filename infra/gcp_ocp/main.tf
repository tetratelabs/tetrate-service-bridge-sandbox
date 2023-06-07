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
    name        = "${var.name_prefix}_project"
  })
}

module "gcp_ocp_base" {
  source      = "../../modules/gcp_ocp/base"
  count       = var.gcp_ocp_region == null ? 0 : 1
  name_prefix = "${var.name_prefix}-${var.cluster_id}"
  project_id  = coalesce(google_project.tsb[0].project_id, var.gcp_project_id)
  region      = var.gcp_ocp_region
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = cidrsubnet(var.cidr, 4, 8 + count.index)
}

module "gcp_ocp_jumpbox" {
  source                  = "../../modules/gcp_ocp/jumpbox"
  count                   = var.gcp_ocp_region == null ? 0 : 1
  name_prefix             = "${var.name_prefix}-${var.cluster_id}"
  region                  = var.gcp_ocp_region
  project_id              = coalesce(var.gcp_project_id, google_project.tsb[0].project_id)
  vpc_id                  = module.gcp_ocp_base[0].vpc_id
  vpc_subnet              = module.gcp_ocp_base[0].vpc_subnets[0]
  tsb_version             = var.tsb_version
  tsb_helm_repository     = var.tsb_helm_repository
  jumpbox_username        = var.jumpbox_username
  machine_type            = var.jumpbox_machine_type
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.gcp_ocp_base[0].registry
  output_path             = var.output_path
  tags                    = local.default_tags
  ocp_pull_secret         = file("${path.module}/../../ocp_pull_secret.json")
  gcp_dns_domain          = var.gcp_dns_domain
  # cluster_name            = var.cluster_name
  cluster_name            = coalesce(var.cluster_name, "gke-${var.gcp_ocp_region}-${var.name_prefix}")
  preemptible_nodes       = var.preemptible_nodes
  k8s_version             = var.gcp_gke_k8s_version
  ssh_key                 = var.ssh_key
  google_service_account  = var.google_service_account
  compute_zone            = var.compute_zone
}