data "dns_a_record_set" "tsb" {
  host = var.address
}

## Shared DNS Zone

data "google_dns_managed_zone" "shared" {
  count = local.shared_zone ? 1 : 0
  project = "dns-terraform-sandbox"
  name = local.zone_name
}

resource "google_dns_record_set" "shared_fqdn" {
  count = local.shared_zone ? 1 : 0
  project = "dns-terraform-sandbox"
  managed_zone = data.google_dns_managed_zone.shared[0].name
  name = "${var.fqdn}."
  type = "A"
  ttl  = 300

  rrdatas = [data.dns_a_record_set.tsb.addrs[0]]
}

## Public DNS Zone

resource "google_dns_managed_zone" "public" {
  count     = local.public_zone ? 1 : 0
  project   = var.project_id
  name      = local.zone_name
  dns_name  = "${local.dns_name}."
}

resource "google_dns_record_set" "public_fqdn" {
  count        = local.public_zone ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.public[0].name
  name         = "${var.fqdn}."
  type         = "A"
  ttl          = 300

  rrdatas = [data.dns_a_record_set.tsb.addrs[0]]
}

## Private DNS Zone

data "google_compute_network" "tsb" {
  count   = local.private_zone ? 1 : 0
  project = var.project_id
  name    = var.vpc_id
}

resource "google_dns_managed_zone" "private" {
  count      = local.private_zone ? 1 : 0
  project    = var.project_id
  name       = local.zone_name
  dns_name   = "${local.dns_name}."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = data.google_compute_network.tsb[0].id
    }
  }
}

resource "google_dns_record_set" "private_fqdn" {
  count        = local.private_zone ? 1 : 0
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private[0].name
  name         = "${var.fqdn}."
  type         = "A"
  ttl          = 300

  rrdatas = [data.dns_a_record_set.tsb.addrs[0]]
}
