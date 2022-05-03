data "aws_route53_zone" "zone" {
  name = var.dns_zone
}

resource "aws_route53_record" "tsb_fqdn" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.tsb_fqdn
  type    = "A"
  ttl     = "30"
  records = [var.tsb_mp_host]
}
