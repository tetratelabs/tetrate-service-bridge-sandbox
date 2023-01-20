variable "name_prefix" {
}

variable "tsb_fqdn" {
}

variable "tsb_mp" {
  default = {
    cloud      = "gcp"
    cluster_id = 0
  }
}

variable "gcp_k8s_regions" {
  default = []
}
