module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = var.project_id
  cluster_name         = var.cluster_name
  location             = var.region
  use_private_endpoint = false

}
