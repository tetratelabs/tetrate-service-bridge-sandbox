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
  network            = var.vpc_id
  subnetwork         = var.vpc_subnet

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  resource_labels = {
    name        = "${var.cluster_name}_tsb_sandbox_blue"
    environment = "${var.name_prefix}_tsb"
    owner       = var.owner
  }

  depends_on = [
    google_project_service.container
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-pool"
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.tsb.name
  node_count = 1

  node_config {
    preemptible  = var.preemptible_nodes
    machine_type = "e2-standard-4"

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
  depends_on = [
    google_container_cluster.tsb
  ]
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "${var.output_path}/${google_container_cluster.tsb.name}-kubeconfig"
}

resource "local_file" "gen_kubeconfig_sh" {
  content         = "gcloud container clusters get-credentials --project ${var.project_id} --region ${var.region} ${var.cluster_name}"
  filename        = "${var.output_path}/generate-${var.cluster_name}-kubeconfig.sh"
  file_permission = "0755"
}
