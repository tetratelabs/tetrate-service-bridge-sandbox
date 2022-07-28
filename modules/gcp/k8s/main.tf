data "google_compute_default_service_account" "default" {
  project = var.project_id
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"
}

resource "google_container_cluster" "tsb" {
  name               = var.cluster_name
  project            = var.project_id
  location           = var.region
  min_master_version = var.k8s_version


  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  depends_on = [
    google_project_service.container
  ]
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "${var.cluster_name}-pool"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.tsb.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = data.google_compute_default_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  depends_on = [
    google_project_service.container
  ]
}

module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"

  project_id           = var.project_id
  cluster_name         = google_container_cluster.tsb.name
  location             = var.region
  use_private_endpoint = false
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "${var.output_path}/${google_container_cluster.tsb.name}-kubeconfig"
}
