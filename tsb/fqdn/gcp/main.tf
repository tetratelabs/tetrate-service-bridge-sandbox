module "register_fqdn" {
  source        = "../../../modules/gcp/register_fqdn"
  dns_zone      = var.dns_zone
  fqdn          = var.fqdn
  address       = var.address
  project_id    = local.project_id
  vpc_id        = local.vpc_id
}
