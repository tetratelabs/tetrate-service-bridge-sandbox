variable "dns_zone" {
    default = null
}
variable "fqdn" {
}
variable "address" {
}
variable "project_id" {
}
variable "vpc_id" {
}

locals {
  shared_zone   = endswith(var.fqdn, ".gcp.cx.tetrate.info")
  private_zone  = endswith(var.fqdn, ".private")
  public_zone   = !local.shared_zone && !local.private_zone

  # If the dns_zone is not set, remove the first part of the FQDN and use it
  dns_name      = coalesce(var.dns_zone, replace(var.fqdn, "/^[^\\.]+\\./", ""))
  zone_name     = replace(local.dns_name, ".", "-")
}
