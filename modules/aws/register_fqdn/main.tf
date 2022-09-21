data "aws_route53_zone" "zone" {
  name = var.dns_zone
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
