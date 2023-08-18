data "aws_route53_zone" "zone" {
  # If the dns_zone is not set, remove the first part of the FQDN and use it
  name = coalesce(var.dns_zone, replace(var.fqdn, "/^[^\\.]+\\./", ""))
}

data "dns_a_record_set" "tsb" {
  host = var.address
}

resource "aws_route53_record" "tsb_fqdn" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.fqdn
  type    = "A"
  ttl     = "30"
  records = [data.dns_a_record_set.tsb.addrs[0]]
}
