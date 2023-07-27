variable "cluster_id" {
  default = null
}
variable "cluster_name" {
  default = null
}

variable "name_prefix" {
  description = "name prefix"
}

variable "cidr" {
  description = "cidr"
  default     = "172.20.0.0/16"
}

variable "tsb_image_sync_username" {
}

variable "tsb_image_sync_apikey" {
}

variable "tsb_version" {
  default = "1.7.0"
}

variable "tsb_helm_repository" {
  default = "https://charts.dl.tetrate.io/public/helm/charts/"
}

variable "jumpbox_username" {
  default = "tsbadmin"
}

variable "aws_k8s_region" {
  default = null
}

variable "aws_eks_k8s_version" {
  default = "1.26"
}

variable "output_path" {
  default = "../../outputs"
}

variable "tetrate_owner" {
}
variable "tetrate_team" {
}
variable "tetrate_purpose" {
  default = "demo"
}
variable "tetrate_lifespan" {
  default = "oneoff"
}
variable "tetrate_customer" {
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