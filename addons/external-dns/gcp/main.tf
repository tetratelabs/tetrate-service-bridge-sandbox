data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../infra/gcp/terraform.tfstate.d/gcp-${var.cluster_id}-${var.gcp_k8s_regions[var.cluster_id]}/terraform.tfstate"
  }
}

data "terraform_remote_state" "dns" {
  backend = "local"
  config = {
    path = "credentials/terraform.tfstate"
  }
}

module "external_dns" {
  source                     = "../../../modules/addons/external-dns"
  cluster_name               = data.terraform_remote_state.infra.outputs.cluster_name
  k8s_host                   = data.terraform_remote_state.infra.outputs.host
  k8s_cluster_ca_certificate = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  k8s_client_token           = data.terraform_remote_state.infra.outputs.token
  dns_provider               = "google"
  tsb_fqdn                   = var.tsb_fqdn
  dns_zone                   = replace(var.tsb_fqdn, "/^[^\\.]+\\./", "")  # Remove the first part of the fqdn
  google_project             = data.terraform_remote_state.dns.outputs.dns_project
  google_service_account_key = data.terraform_remote_state.dns.outputs.dns_credentials
}
