output "pkey" {
  value = tls_private_key.generated.private_key_pem
}

output "public_ip" {
  value = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}

output "compute_zone" {
  value = google_compute_instance.jumpbox.zone
}

output "cluster_name" {
  value = var.cluster_name
}

# output "host" {
  # Figure out gke_auth OCP equivalent
  # value = module.gke_auth.host
# }

# output "cluster_ca_certificate" {
  # Figure out gke_auth OCP equivalent
  # value = base64encode(module.gke_auth.cluster_ca_certificate)
# }

# output "token" {
  # Figure out gke_auth OCP equivalent
  # value = module.gke_auth.token
# }