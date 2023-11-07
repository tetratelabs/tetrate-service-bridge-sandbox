variable "cluster" {
  description = "An object containing the cluster configuration"
  type = object({
    cloud  = string
    index  = number
    name   = string
    region = string
    tetrate = object({
      control_plane    = optional(bool)
      management_plane = optional(bool)
    })
    version   = optional(string)
    workspace = string
  })
}

locals {
  cluster_defaults = {
    tetrate = {
      control_plane    = false
      management_plane = false
    }
    version = "1.27"
  }
  cluster = {
    cloud  = var.cluster.cloud
    index  = var.cluster.index
    name   = var.cluster.name
    region = var.cluster.region
    tetrate = {
      control_plane    = coalesce(var.cluster.tetrate.control_plane, local.cluster_defaults.tetrate.control_plane)
      management_plane = coalesce(var.cluster.tetrate.management_plane, local.cluster_defaults.tetrate.management_plane)
    }
    version   = coalesce(var.cluster.version, local.cluster_defaults.version)
    workspace = var.cluster.workspace
  }
}

variable "tetrate" {
  description = "An object containing global tetrate configuration"
  type        = map(any)
  default     = {}
  /*
    fqdn                = string
    helm_password       = optional(string)
    helm_repository     = optional(string)
    helm_username       = optional(string)
    helm_version        = optional(string)
    image_sync_apikey   = string
    image_sync_username = string
    organization        = string
    password            = string
    username            = optional(string)
    version             = string
  */
}

locals {
  tetrate_defaults = {
    helm_password   = ""
    helm_repository = "https://charts.dl.tetrate.io/public/helm/charts/"
    helm_username   = ""
    helm_version    = null
    username        = "admin"
  }
  tetrate = merge(local.tetrate_defaults, var.tetrate)
}

variable "name_prefix" {
  description = "name prefix"
  type        = string
}

variable "tags" {
  description = "A map of resource tags, with 'tetrate_owner' and 'tetrate_team' as mandatory tags"
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

variable "output_path" {
  description = "output path"
  type        = string
  default     = "../../../outputs"
}

variable "addon_config" {
  description = "An object containing addon configuration"
  type        = map(string)
  default     = {}
  /*
    dns_annotation_filter = optional(string)
    dns_interval          = optional(string)
    dns_label_filter      = optional(string)
    dns_sources           = optional(string)
    dns_zone              = string
  */
}

locals {
  addon_config_defaults = {
    dns_annotation_filter = ""
    dns_interval          = "5s"
    dns_label_filter      = ""
    dns_sources           = "service"
  }
  addon_config = merge(local.addon_config_defaults, var.addon_config)
}
