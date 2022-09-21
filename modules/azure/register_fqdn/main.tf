data "azurerm_dns_zone" "zone" {
  resource_group_name = "dns-terraform-sandbox"
  name = var.dns_zone
}

data "dns_a_record_set" "tsb" {
  host = var.address
}

resource "azurerm_dns_a_record" "example" {
  name                = split(".",var.fqdn,)[0]
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = "dns-terraform-sandbox"
  ttl                 = 30
  records             = [data.dns_a_record_set.tsb.addrs[0]]
}
