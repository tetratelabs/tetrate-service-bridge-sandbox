

resource "random_string" "random" {
  length  = 8
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  name            = "${var.name_prefix}-tsb"
  project_id      = "${var.name_prefix}-tsb-${random_string.random.result}"
  org_id          = var.org_id
  billing_account = var.billing_id
}

resource "google_project_service" "compute" {
  project = google_project.tsb.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "containerregistry" {
  project = google_project.tsb.project_id
  service = "containerregistry.googleapis.com"
}


resource "time_sleep" "wait_60_seconds" {
  depends_on = [
    google_project_service.compute,
    google_project_service.containerregistry
  ]
  create_duration = "60s"
}

resource "google_compute_network" "tsb" {
  name                    = "${var.name_prefix}-vpc"
  project                 = google_project.tsb.project_id
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "google_compute_router" "tsb" {
  name    = "${var.name_prefix}-router"
  project = google_project.tsb.project_id
  region  = var.region
  network = google_compute_network.tsb.self_link
}

data "google_compute_zones" "available" {
  project = google_project.tsb.project_id
  region  = var.region
  depends_on = [
    time_sleep.wait_60_seconds
  ]
}

resource "google_compute_subnetwork" "tsb" {
  count = min(var.min_az_count, var.max_az_count)
  name  = "${var.name_prefix}-subnet${data.google_compute_zones.available.names[count.index]}"

  project = google_project.tsb.project_id
  region  = var.region
  network = google_compute_network.tsb.self_link

  ip_cidr_range = cidrsubnet(var.cidr, 8, count.index)
}

resource "google_compute_router_nat" "tsb" {
  name = "${var.name_prefix}-nat"

  project = google_project.tsb.project_id
  region  = var.region
  router  = google_compute_router.tsb.name

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

resource "google_compute_firewall" "tsb" {
  name = "${var.name_prefix}-firewall"

  project = google_project.tsb.project_id
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
