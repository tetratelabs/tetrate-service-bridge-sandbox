data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = var.project_id
  cluster_name         = var.cluster_name
  location             = data.google_compute_zones.available.names[0]
  use_private_endpoint = false

}
