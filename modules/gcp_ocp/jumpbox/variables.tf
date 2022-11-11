variable "name_prefix" {
  description = "name prefix"
}

variable "region" {
}

variable "project_id" {
}

variable "vpc_id" {
}

variable "vpc_subnet" {
}

variable "registry" {
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_version" {
}

variable "jumpbox_username" {
}

variable "output_path" {
}

variable "ocp_pull_secret" {
}

variable "gcp_dns_domain" {
}

variable "cluster_name" {
}

variable "ssh_key" {
}

variable "google_service_account" {
}

variable "myaccount" {
  default = ""
}

variable "dns_zone" {
  default = ""
}

variable "fqdn" {
  default = "ocp.gcp.cx.tetrate.info"
}

variable "address" {
  default = "ocp.gcp.cx.tetrate.info."
}

variable "ssh_user" {
  default = ""
}

variable "ssh_pub_key_file" {
  default = ""
}
