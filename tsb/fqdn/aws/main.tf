module "register_fqdn" {
  source        = "../../../modules/aws/register_fqdn"
  dns_zone      = var.dns_zone
  fqdn          = var.fqdn
  address       = var.address
}
