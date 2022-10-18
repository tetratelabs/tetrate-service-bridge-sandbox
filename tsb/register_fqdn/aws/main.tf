data "terraform_remote_state" "tsb_mp" {
  backend = "local"
  config = {
    path = "../../mp/terraform.tfstate"
  }
}

module "aws_register_fqdn" {
  source   = "../../../modules/aws/register_fqdn"
  dns_zone = "cx.tetrate.info"
  fqdn     = var.tsb_fqdn
   address  = data.terraform_remote_state.tsb_mp.outputs.ingress_ip != "" ? data.terraform_remote_state.tsb_mp.outputs.ingress_ip : data.terraform_remote_state.tsb_mp.outputs.ingress_hostname
}
