variable "cluster_name" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "cert_manager_enabled" {
}

variable "cert_manager_version" {
  default = "v1.10.2"
}
