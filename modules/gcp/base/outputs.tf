output "vpc_id" {
  value = google_compute_network.tsb.self_link
}

output "vpc_subnets" {
  value = google_compute_subnetwork.tsb.*.self_link
}

output "registry" {
  value = "gcr.io/${var.project_id}"
}

output "cidr" {
  value = var.cidr
}
