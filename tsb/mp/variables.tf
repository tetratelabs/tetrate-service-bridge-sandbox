variable "cloud" {
  default = null
}
variable "cluster_id" {
  default = null
}
variable "cluster_name" {
  default = null
}
variable "cluster_region" {
  default = null
}
variable "owner" {
  default = "tsb-sandbox@tetrate.io"
}

variable "name_prefix" {
  description = "name prefix"
}

variable "cidr" {
  description = "cidr"
  default     = "172.20.0.0/16"
}

variable "tsb" {
  type    = map(any)
  default = {}
}

locals {
  tsb_defaults = {
    fqdn                     = "toa.cx.tetrate.info"
    helm_repository          = "https://charts.dl.tetrate.io/public/helm/charts/"
    helm_repository_password = "demo"
    helm_repository_username = "demo"
    helm_version             = "demo"
    image_sync_apikey        = "demo"
    image_sync_username      = "demo"
    organisation             = "tetrate"
    password                 = "admin123"
    username                 = "admin"
    version                  = "1.7.0"
  }
  tsb = merge(local.tsb_defaults, var.tsb)
}

variable "mp_as_tier1_cluster" {
  default = true
}
variable "jumpbox_username" {
  default = "tsbadmin"
}

variable "gcp_project_id" {
  default = null
}

variable "gcp_org_id" {
  default = "775566979306"
}

variable "gcp_billing_id" {
  default = "0183E5-447B34-776DEB"
}
variable "aws_eks_k8s_version" {
  default = "1.22"
}

variable "azure_aks_k8s_version" {
  default = "1.23.5"
}

variable "gcp_gke_k8s_version" {
  default = "1.21.12-gke.1500"
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