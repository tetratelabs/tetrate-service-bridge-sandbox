variable "cloud" {
  default = "azure"
}

variable "cluster_id" {
  default = null
}

variable "azure_k8s_region" {
  default = []
}

locals {
  k8s_region = var.azure_k8s_region
}

  