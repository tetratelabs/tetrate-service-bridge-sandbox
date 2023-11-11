output "project_id" {
  value = var.project_id
}
output "vpc_id" {
  value = google_compute_network.tsb.self_link
}

output "vpc_subnets" {
  value = google_compute_subnetwork.tsb.*.self_link
}

output "registry" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${var.name_prefix}-tsb-repo/"
}

output "registry_username" {
  value = "_json_key"
}
output "registry_password" {
  value = base64decode(google_service_account_key.gcr_pull_key.private_key)
}

output "cidr" {
  value = var.cidr
}
