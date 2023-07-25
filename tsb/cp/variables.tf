variable "cloud" {
  default = null
}
variable "cluster_id" {
  default = null
}
variable "cluster_name" {
  default = null
}
variable "owner" {
  default = "tsb-sandbox@tetrate.io"
}

locals {
  infra = data.terraform_remote_state.infra

  k8s_regions = var.cloud == "aws" ? var.aws_k8s_regions : (
    var.cloud == "azure" ? var.azure_k8s_regions : var.gcp_k8s_regions
  )
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

variable "tsb_helm_repository_username" {
  default = ""
}

variable "tsb_helm_repository_password" {
  default = ""
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

variable "gcp_k8s_regions" {
  default = []
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

variable "ratelimit_enabled" {
  default = true
}

variable "identity_propagation_enabled" {
  default = false
}