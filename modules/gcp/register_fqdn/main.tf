data "google_dns_managed_zone" "zone" {
  project = "dns-terraform-sandbox"
   # If the dns_zone is not set, remove the first part of the FQDN and use it
  name = replace(coalesce(var.dns_zone, replace(var.fqdn, "/^[^\\.]+\\./", "")), ".", "-")
}

data "dns_a_record_set" "tsb" {
  host = var.address
}

resource "google_dns_record_set" "tsb_fqdn" {
  project = "dns-terraform-sandbox"
  managed_zone = data.google_dns_managed_zone.zone.name
  name = "${var.fqdn}."
  type = "A"
  ttl  = 300

  rrdatas = [data.dns_a_record_set.tsb.addrs[0]]
}