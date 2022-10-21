variable "name_prefix" {
}
variable "dns_zone" {
    default = null
}
variable "fqdn" {
}
variable "address" {
}
variable "region" {
}
variable "cluster_id" {
  default = 0
}

locals {
  shared_zone   = endswith(var.fqdn, ".gcp.cx.tetrate.info")
  private_zone  = endswith(var.fqdn, ".private")
  public_zone   = !local.shared_zone && !local.private_zone

  # If the dns_zone is not set, remove the first part of the FQDN and use it
  dns_name      = coalesce(var.dns_zone, replace(var.fqdn, "/^[^\\.]+\\./", ""))
  zone_name     = replace(local.dns_name, ".", "-")

  # We can get the project ID by parsing it from the `registry` output variable for the MP cluster install
  state = jsondecode(file("../../../infra/gcp/terraform.tfstate.d/gcp-${var.cluster_id}-${var.region}/terraform.tfstate"))
  project_id = trimprefix(local.state.outputs.registry.value, "gcr.io/")
}
