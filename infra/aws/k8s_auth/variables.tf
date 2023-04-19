variable "cloud" {
  default = "aws"
}

variable "cluster_id" {
  default = null
}

variable "aws_k8s_region" {
  default = []
}

locals {
  k8s_region = var.aws_k8s_region
}

  