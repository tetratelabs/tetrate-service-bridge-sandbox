variable "cluster_id" {
  type    = string
  default = null
}

variable "cluster_name" {
  type    = string
  default = null
}

variable "name_prefix" {
  type        = string
  description = "name prefix"
}

variable "cidr" {
  type        = string
  description = "cidr"
  default     = "172.20.0.0/16"
}

variable "tsb_image_sync_username" {
  type = string
}

variable "tsb_image_sync_apikey" {
  type = string
}

variable "tsb_version" {
  type    = string
  default = "1.7.0"
}

variable "tsb_helm_repository" {
  type    = string
  default = "https://charts.dl.tetrate.io/public/helm/charts/"
}

variable "jumpbox_username" {
  type    = string
  default = "tsbadmin"
}

variable "jumpbox_machine_type" {
  type    = string
  default = "n1-standard-2"
}


variable "gcp_k8s_region" {
  type    = string
  default = null
}

variable "gcp_project_id" {
  type    = string
  default = null
}

variable "gcp_org_id" {
  type    = string
  default = "775566979306"
}

variable "gcp_billing_id" {
  type    = string
  default = "0183E5-447B34-776DEB"
}

variable "gcp_gke_k8s_version" {
  type    = string
  default = "1.26"
}

variable "output_path" {
  type    = string
  default = "../../outputs"
}

variable "preemptible_nodes" {
  type    = string
  default = false
}

variable "tetrate_owner" {
  type = string
}

variable "tetrate_team" {
  type = string
}

variable "tetrate_purpose" {
  type    = string
  default = "demo"
}

variable "tetrate_lifespan" {
  type    = string
  default = "oneoff"
}

variable "tetrate_customer" {
  type    = string
  default = "internal"
}

locals {
  default_tags = {
    tetrate_owner    = replace(coalesce(var.tetrate_owner, var.tsb_image_sync_username), "/\\W+/", "_")
    tetrate_team     = replace(var.tetrate_team, "/\\W+/", "_")
    tetrate_purpose  = var.tetrate_purpose
    tetrate_lifespan = var.tetrate_lifespan
    tetrate_customer = var.tetrate_customer
    environment      = var.name_prefix
  }
}
