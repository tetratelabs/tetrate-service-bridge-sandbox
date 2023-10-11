############################## cluster unique vars ##############################

variable "cloud_provider" {
  default     = "aws"
  description = "Cloud provider"
  type        = string
}

variable "cluster_id" {
  default     = null
  description = "Kubernetes global unique cluster id (0..N)"
  type        = string
}

variable "cluster_region" {
  default     = null
  description = "Kubernetes cluster region"
  type        = string
}

############################## global config tfvars ##############################

variable "cp_clusters" {
  description = "A list of control plane configuration objects"
  type = list(object({
    cloud_provider = string
    name           = string
    region         = string
    version        = string
  }))
}

variable "dns_provider" {
  description = "DNS provider used for exposing the TSB GUI"
  type        = string
}

variable "mp_cluster" {
  description = "Management plane configuration object"
  type = object({
    cloud_provider = string
    name           = string
    region         = string
    tier1          = bool
    version        = string
  })
}

variable "name_prefix" {
  description = "Unique name prefix used for your resources"
  type        = string
}

variable "tags" {
  description = "A map of resource tags, with 'owner' and 'team' as mandatory tags"
  type        = map(string)
  default     = {}
}

locals {
  mandatory_tags = {
    tetrate_owner = try(var.tags["tetrate_owner"], error("Missing 'tetrate_owner' tag")),
    tetrate_team  = try(var.tags["tetrate_team"], error("Missing 'tetrate_team' tag")),
  }
  optional_tags = {
    environment      = coalesce(lookup(var.tags, "environment", null), var.name_prefix)
    tetrate_customer = coalesce(lookup(var.tags, "tetrate_customer", null), "internal")
    tetrate_lifespan = coalesce(lookup(var.tags, "tetrate_lifespan", null), "oneoff")
    tetrate_purpose  = coalesce(lookup(var.tags, "tetrate_purpose", null), "demo")
  }
  all_tags_merged = merge(local.mandatory_tags, local.optional_tags, var.tags)
  tags = {
    for k, v in local.all_tags_merged : k => replace(v, ":", "_")
  }
}

variable "tsb" {
  description = "A map of tsb configuration, with 'fqdn', 'image_sync_apikey', 'image_sync_username' and 'version' as mandatory configuration"
  type        = map(string)
  default     = {}
}

locals {
  mandatory_tsb = {
    fqdn                = try(var.tsb["fqdn"], error("Missing 'fqdn' tsb configuration")),
    image_sync_apikey   = try(var.tsb["image_sync_apikey"], error("Missing 'image_sync_apikey' tsb configuration")),
    image_sync_username = try(var.tsb["image_sync_username"], error("Missing 'image_sync_username' tsb configuration")),
    version             = try(var.tsb["version"], error("Missing 'version' tsb configuration")),
  }
  optional_tsb = {
    helm_repository          = coalesce(lookup(var.tsb, "helm_repository", null), "https://charts.dl.tetrate.io/public/helm/charts/")
    helm_repository_password = coalesce(lookup(var.tsb, "helm_repository_password", null), var.tsb["image_sync_apikey"])
    helm_repository_username = coalesce(lookup(var.tsb, "helm_repository_username", null), var.tsb["image_sync_username"])
    helm_version             = coalesce(lookup(var.tsb, "helm_version", null), var.tsb["version"])
    organisation             = coalesce(lookup(var.tsb, "organisation", null), "tetrate")
    password                 = coalesce(lookup(var.tsb, "password", null), "Tetrate123")
    username                 = coalesce(lookup(var.tsb, "username", null), "admin")
  }
  tsb = merge(local.mandatory_tsb, local.optional_tsb)
}
