provider "azurerm" {
  features {}
}
module "register_fqdn" {
  source        = "../../../modules/azure/register_fqdn"
  dns_zone      = var.dns_zone
  fqdn          = var.fqdn
  address       = var.address
}
