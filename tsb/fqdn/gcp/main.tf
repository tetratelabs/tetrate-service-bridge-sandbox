data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../infra//${var.tsb_mp["cloud"]}/terraform.tfstate.d/${var.tsb_mp["cloud"]}-${var.tsb_mp["cluster_id"]}-${local.k8s_regions[tonumber(var.tsb_mp["cluster_id"])]}/terraform.tfstate"
  }
}

module "register_fqdn" {
  source        = "../../../modules/gcp/register_fqdn"
  dns_zone      = var.dns_zone
  fqdn          = var.fqdn
  address       = var.address
  project_id    = local.infra[var.tsb_mp["cluster_id"]]["outputs"].registry.project_id
  vpc_id        = local.infra[var.tsb_mp["cluster_id"]]["outputs"].registry.vpc_id
}
