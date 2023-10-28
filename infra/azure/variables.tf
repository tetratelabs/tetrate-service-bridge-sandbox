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
  default     = "172.16.0.0/12"
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

variable "azure_k8s_region" {
  type    = string
  default = null
}

variable "azure_aks_k8s_version" {
  type    = string
  default = "1.26"
}

variable "output_path" {
  type    = string
  default = "../../outputs"
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
    "tetrate:owner"    = coalesce(var.tetrate_owner, replace(var.tsb_image_sync_username, "/\\W+/", "-"))
    "tetrate:team"     = var.tetrate_team
    "tetrate:purpose"  = var.tetrate_purpose
    "tetrate:lifespan" = var.tetrate_lifespan
    "tetrate:customer" = var.tetrate_customer
    "environment"      = var.name_prefix
  }
}