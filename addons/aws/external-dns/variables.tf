variable "cloud" {
  default = null
}

variable "cluster_id" {
  default = null
}

variable "name_prefix" {
  description = "name prefix"
}

variable "output_path" {
  default = "../../../outputs"
}

variable "tsb_image_sync_username" {
}

variable "aws_k8s_regions" {
  default = []
}

locals {
  k8s_regions = var.aws_k8s_regions
}

variable "tetrate" {
  type    = map(any)
  default = {}
}

locals {
  tetrate_defaults = {
    customer = "internal"
    lifespan = "oneoff"
    owner    = "demo"
    purpose  = "demo"
    team     = "demo"
  }
  tetrate = merge(local.tetrate_defaults, var.tetrate)
}

locals {
  default_tags = {
    "tetrate_customer" = local.tetrate.customer
    "tetrate_lifespan" = local.tetrate.lifespan
    "tetrate_owner"    = coalesce(local.tetrate.owner, replace(local.tsb.image_sync_username, "/\\W+/", "-"))
    "tetrate_purpose"  = local.tetrate.purpose
    "tetrate_team"     = local.tetrate.team
    "environment"      = var.name_prefix
  }
}

variable "external_dns_annotation_filter" {
  default = ""
}

variable "external_dns_label_filter" {
  default = ""
}

variable "external_dns_sources" {
  default = "service"
}

variable "external_dns_interval" {
  default = "5s"
}

variable "external_dns_aws_dns_zone" {
}

