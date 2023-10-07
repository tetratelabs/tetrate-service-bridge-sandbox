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

variable "jumpbox_username" {
  type    = string
  default = "tsbadmin"
}

variable "tsb" {
  type    = map(any)
  default = {}
}

locals {
  tsb_defaults = {
    version             = "1.7.0"
    image_sync_username = "demo"
    image_sync_apikey   = "demo"
    helm_repository     = "https://charts.dl.tetrate.io/public/helm/charts/"
  }
  tsb = merge(local.tsb_defaults, var.tsb)
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
    "tetrate:customer" = local.tetrate.customer
    "tetrate:lifespan" = local.tetrate.lifespan
    "tetrate:owner"    = coalesce(local.tetrate.owner, replace(local.tsb.image_sync_username, "/\\W+/", "-"))
    "tetrate:purpose"  = local.tetrate.purpose
    "tetrate:team"     = local.tetrate.team
    "environment"      = var.name_prefix
  }
}