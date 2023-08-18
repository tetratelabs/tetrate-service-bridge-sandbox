variable "cloud" {
  type    = string
  default = "gcp"
}

variable "cluster_id" {
  type    = string
  default = null
}

variable "gcp_k8s_region" {
  default = []
}

locals {
  k8s_region = var.gcp_k8s_region
}

  