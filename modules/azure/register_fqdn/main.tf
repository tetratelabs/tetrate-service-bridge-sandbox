data "azurerm_dns_zone" "zone" {
  resource_group_name = "dns-terraform-sandbox"
  # If the dns_zone is not set, remove the first part of the FQDN and use it
  name = coalesce(var.dns_zone, replace(var.fqdn, "/^[^\\.]+\\./", ""))
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
