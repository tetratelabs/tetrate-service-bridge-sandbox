variable "dns_zone" {
    default = null
}
variable "fqdn" {
}
variable "address" {
}

locals {
  infra = data.terraform_remote_state.infra

  k8s_regions = var.tsb_mp["cloud"] == "aws" ? var.aws_k8s_regions : (
    var.tsb_mp["cloud"] == "azure" ? var.azure_k8s_regions : var.gcp_k8s_regions
  )
}