output "project_name" {
  value = google_project.tsb.name
}

output "project_id" {
  value = google_project.tsb.project_id
}

output "vpc_id" {
  value = google_compute_network.tsb.self_link
}

output "vpc_subnets" {
  value = google_compute_subnetwork.tsb.*.self_link
}

output "registry" {
  value = "gcr.io/${google_project.tsb.project_id}"
}


