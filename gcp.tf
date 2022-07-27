resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  count           = var.gcp_project_id == null ? 1 : 0
  name            = "${var.name_prefix}-tsb"
  project_id      = "${var.name_prefix}-tsb-${random_string.random.result}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id
}

module "gcp_base" {
  count       = length(var.gcp_k8s_regions)
  source      = "./modules/gcp/base"
  name_prefix = "${var.name_prefix}-${var.gcp_k8s_regions[count.index]}-${count.index}"
  project_id  = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region      = var.gcp_k8s_regions[count.index]
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = cidrsubnet(var.cidr, 4, 8 + count.index)
}

module "gcp_jumpbox" {
  count                   = length(var.gcp_k8s_regions) > 0 ? 1 : 0
  source                  = "./modules/gcp/jumpbox"
  name_prefix             = "${var.name_prefix}-${var.gcp_k8s_regions[count.index]}-${count.index}"
  region                  = var.gcp_k8s_regions[0]
  project_id              = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  vpc_id                  = module.gcp_base[0].vpc_id
  vpc_subnet              = module.gcp_base[0].vpc_subnets[0]
  tsb_version             = var.tsb_version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb_image_sync_username
  tsb_image_sync_apikey   = var.tsb_image_sync_apikey
  registry                = module.gcp_base[0].registry
}

module "gcp_k8s" {
  source       = "./modules/gcp/k8s"
  count        = length(var.gcp_k8s_regions)
  name_prefix  = "${var.name_prefix}-${var.gcp_k8s_regions[count.index]}-${count.index}"
  cluster_name = "${var.name_prefix}-gke-${count.index + 1}"
  project_id   = var.gcp_project_id == null ? google_project.tsb[0].project_id : var.gcp_project_id
  region       = var.gcp_k8s_regions[count.index]
  k8s_version  = var.gcp_gke_k8s_version
  depends_on   = [module.gcp_jumpbox[0]]
}
