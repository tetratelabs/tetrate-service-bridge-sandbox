variable "dns_zone" {
    default = null
}
variable "fqdn" {
}
variable "address" {
}

variable "tsb_mp" {
  default = {}
}
variable "aws_k8s_regions" {
  default = []
}
locals {
  infra = data.terraform_remote_state.infra
  k8s_regions = var.aws_k8s_regions
}