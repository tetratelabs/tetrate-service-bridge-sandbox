data "terraform_remote_state" "infra" {
  backend = "local"
  config = {
    path = "../../../../infra/gcp/terraform.tfstate.d/gcp-${var.tsb_mp["cluster_id"]}-${var.gcp_k8s_regions[tonumber(var.tsb_mp["cluster_id"])]}/terraform.tfstate"
  }
}

locals {
  dns_project = endswith(var.tsb_fqdn, ".gcp.cx.tetrate.info") ? "dns-terraform-sandbox" : data.terraform_remote_state.infra.outputs.project_id
}

resource "google_service_account" "external_dns" {
  project = local.dns_project
  account_id = "${var.name_prefix}-external-dns"
}

resource "google_project_iam_member" "dns_admin" {
  project = local.dns_project
  role = "roles/dns.admin"
  member = "serviceAccount:${google_service_account.external_dns.email}"
}

resource "google_service_account_key" "external_dns_key" {
  service_account_id = google_service_account.external_dns.name
}
