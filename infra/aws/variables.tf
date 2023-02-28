variable "cloud" {
  default = null
}
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

variable "tsb_username" {
  default = "admin"
}

variable "tsb_password" {
  default = ""
}

variable "tsb_version" {
  default = "1.5.0"
}
variable "tsb_helm_repository" {
  default = "https://charts.dl.tetrate.io/public/helm/charts/"
}
variable "tsb_helm_version" {
  default = null
}
variable "tsb_fqdn" {
  default = "toa.sandbox.tetrate.io"
}
variable "dns_zone" {
  default = "sandbox.tetrate.io"
}

variable "tsb_org" {
  default = "tetrate"
}

variable "mp_as_tier1_cluster" {
  default = true
}
variable "jumpbox_username" {
  default = "tsbadmin"
}

variable "aws_k8s_regions" {
  default = []
}

# variable to communicated over a workspace only
variable "aws_k8s_region" {
  default = null
}

variable "azure_k8s_regions" {
  default = []
}

variable "aws_eks_k8s_version" {
  default = "1.23"
}

variable "tsb_mp" {
  default = {
    cloud      = "azure"
    cluster_id = 0
  }
}

variable "output_path" {
  default = "../../outputs"
}

variable "cert-manager_enabled" {
  default = true
}

variable "tetrate_owner" {
    default = null
}
variable "tetrate_team" {
    default = "tetrate-service-bridge-sandbox"
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
variable "external_dns_enabled" {
  default = true
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
  default = "aws.sandbox.tetrate.io"
}