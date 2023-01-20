variable "cluster_name" {
}

variable "k8s_host" {
}

variable "k8s_cluster_ca_certificate" {
}

variable "k8s_client_token" {
}

variable "tsb_fqdn" {
}

variable "dns_provider" {
}

variable "dns_zone" {
}

# Provider specific variables. All of them should be optional to allow
# configuring only the ones for the provider being used.

variable "google_project" {
  default = ""
}

variable "google_service_account_key" {
  default = ""
  description = "Contents of the service account key JSON file"
}
