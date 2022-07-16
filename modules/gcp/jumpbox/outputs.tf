output "pkey" {
  value = tls_private_key.generated.private_key_pem
}

output "public_ip" {
  value = google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip
}
