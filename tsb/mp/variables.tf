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
    cloud     = var.cluster.cloud
    index     = var.cluster.index
    name      = var.cluster.name
    region    = var.cluster.region
    tetrate   = {
      control_plane    = coalesce(var.cluster.tetrate.control_plane, local.cluster_defaults.tetrate.control_plane)
      management_plane = coalesce(var.cluster.tetrate.management_plane, local.cluster_defaults.tetrate.management_plane)
    }
    version   = coalesce(var.cluster.version, local.cluster_defaults.version)
    workspace = var.cluster.workspace
  }
}

variable "tetrate" {
  description = "An object containing global tetrate configuration"
  type = object({
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
  })
}

locals {
  tetrate_defaults = {
    helm_password   = ""
    helm_repository = "https://charts.dl.tetrate.io/public/helm/charts/"
    helm_username   = ""
    helm_version    = null
    username        = "admin"
  }
  tetrate = {
    fqdn                = var.tetrate.fqdn
    helm_password       = coalesce(var.tetrate.helm_password, local.tetrate_defaults.helm_password)
    helm_repository     = coalesce(var.tetrate.helm_repository, local.tetrate_defaults.helm_repository)
    helm_username       = coalesce(var.tetrate.helm_username, local.tetrate_defaults.helm_username)
    helm_version        = coalesce(var.tetrate.helm_version, local.tetrate_defaults.helm_version)
    image_sync_apikey   = var.tetrate.image_sync_apikey
    image_sync_username = var.tetrate.image_sync_username
    organization        = var.tetrate.organization
    password            = var.tetrate.password
    username            = coalesce(var.tetrate.username, local.tetrate_defaults.username)
    version             = var.tetrate.version
  }
}

variable "name_prefix" {
  description = "name prefix"
  type        = string
}

variable "output_path" {
  description = "output path"
  default = "../../outputs"
}

variable "cert-manager_enabled" {
  description = "enable cert-manager"
  default = true
}