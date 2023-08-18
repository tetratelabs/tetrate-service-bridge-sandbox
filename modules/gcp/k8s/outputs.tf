output "host" {
  value = module.gke_auth.host
}

output "cluster_ca_certificate" {
  value = base64encode(module.gke_auth.cluster_ca_certificate)
}

output "token" {
  value = module.gke_auth.token
}

output "client_certificate" {
  value = ""
}

output "client_key" {
  value = ""
}

output "cluster_name" {
  value = var.cluster_name
}

output "locality_region" {
  value = var.region
}
