variable "name_prefix" {
  description = "name prefix"
}

variable "cluster_name" {
  description = "cluster name"
}

variable "resource_group_name" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "tags" {
  type = map
}

variable "dns_zone" {
}

variable "annotation_filter" {
}

variable "label_filter" {
}

variable "sources" {
}

variable "interval" {
}

variable "external_dns_enabled" {
}

locals {
  shared_zone   = endswith(var.dns_zone, "azure.sandbox.tetrate.io")
  private_zone  = endswith(var.dns_zone, ".private")

  dns_name      = var.dns_zone
  zone_name     = replace(local.dns_name, ".", "-")
}