data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/gcp/terraform.tfstate.d/gcp-${var.tsb_mp["cluster_id"]}-${var.gcp_k8s_regions[tonumber(var.tsb_mp["cluster_id"])]}/terraform.tfstate"
  }
}

module "register_fqdn" {
  source        = "../../../modules/gcp/register_fqdn"
  dns_zone      = var.dns_zone
  fqdn          = var.fqdn
  address       = var.address
  project_id    = data.terraform_remote_state.infra.outputs.project_id
  vpc_id        = reverse(split("/", data.terraform_remote_state.infra.outputs.vpc_id))[0]
}
