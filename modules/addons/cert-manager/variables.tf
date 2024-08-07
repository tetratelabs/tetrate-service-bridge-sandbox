variable "cluster_name" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "cert-manager_enabled" {
}

variable "cert-manager_version" {
  default = "v1.15.2"
}
