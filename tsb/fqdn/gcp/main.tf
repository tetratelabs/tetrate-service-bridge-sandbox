data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/gcp/terraform.tfstate.d/gcp-${var.cluster_id}-${var.cluster_region}/terraform.tfstate"
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
