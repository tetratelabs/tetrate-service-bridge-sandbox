resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "dns" {
  project = var.project_id
  service = "dns.googleapis.com"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [
    google_project_service.compute,
    google_project_service.artifactregistry,
    google_project_service.dns
  ]
  create_duration = "60s"
}

resource "google_compute_network" "tsb" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "google_compute_router" "tsb" {
  name    = "${var.name_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.tsb.self_link
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "google_compute_subnetwork" "tsb" {
  count = 1
  name  = "${var.name_prefix}-subnet${data.google_compute_zones.available.names[count.index]}"

  project = var.project_id
  region  = var.region
  network = google_compute_network.tsb.self_link

  ip_cidr_range = cidrsubnet(var.cidr, 2, count.index)

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = cidrsubnet(var.cidr, 2, count.index + 1)
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = cidrsubnet(var.cidr, 2, count.index + 2)
  }
}

resource "google_compute_router_nat" "tsb" {
  name = "${var.name_prefix}-nat"

  project = var.project_id
  region  = var.region
  router  = google_compute_router.tsb.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

resource "google_compute_firewall" "tsb" {
  name = "${var.name_prefix}-firewall"

  project = var.project_id
  network = google_compute_network.tsb.self_link

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  priority = "1000"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

}

resource "google_service_account" "gcr_pull" {
  project    = var.project_id
  account_id = "${var.name_prefix}-gcr-pull"
}
resource "google_project_iam_member" "storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gcr_pull.email}"
}
resource "google_project_iam_member" "artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gcr_pull.email}"
}

resource "google_service_account_key" "gcr_pull_key" {
  service_account_id = google_service_account.gcr_pull.name
}

resource "google_artifact_registry_repository" "tsb" {
  project       = var.project_id
  location      = var.region
  repository_id = "${var.name_prefix}-tsb-repo"
  format        = "DOCKER"
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}