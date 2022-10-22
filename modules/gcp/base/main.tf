resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "containerregistry" {
  project = var.project_id
  service = "containerregistry.googleapis.com"
}

resource "google_project_service" "dns" {
  project = var.project_id
  service = "dns.googleapis.com"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [
    google_project_service.compute,
    google_project_service.containerregistry,
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
  count = min(var.min_az_count, var.max_az_count)
  name  = "${var.name_prefix}-subnet${data.google_compute_zones.available.names[count.index]}"

  project = var.project_id
  region  = var.region
  network = google_compute_network.tsb.self_link

  ip_cidr_range = cidrsubnet(var.cidr, 4, count.index)
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
