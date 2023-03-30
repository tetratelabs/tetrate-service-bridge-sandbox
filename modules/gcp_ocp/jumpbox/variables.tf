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

variable "tsb_helm_repository" {
  default = ""
}

variable "jumpbox_username" {
}

variable "machine_type" {
}

variable "output_path" {
}

variable "tags" {
  type = map
}

variable "ocp_pull_secret" {
}

variable "ocp_pull_secret_file" {
  default = ""
}

variable "gcp_dns_domain" {
  default = "gcp.sandbox.tetrate.io"
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
  default = "sandbox.tetrate.io"
}

variable "fqdn" {
  default = "gcp.sandbox.tetrate.io"
}

variable "address" {
  default = "gcp.sandbox.tetrate.io."
}

variable "ssh_user" {
  default = ""
}

variable "ssh_pub_key_file" {
  default = ""
}

variable "tetrate_owner" {
  default = "michael@tetrate.io"
}
