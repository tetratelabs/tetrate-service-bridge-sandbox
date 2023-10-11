output "registry" {
  value = module.gcp_base.registry
}

output "registry_username" {
  value = module.gcp_base.registry_username
}

output "registry_password" {
  value     = module.gcp_base.registry_password
  sensitive = true
}

output "public_ip" {
  value = module.gcp_jumpbox.public_ip
}

output "pkey" {
  value     = module.gcp_jumpbox.pkey
  sensitive = true
}

output "cluster_name" {
  value = module.gcp_k8s.cluster_name
}

output "host" {
  value     = module.gcp_k8s.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.gcp_k8s.cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.gcp_k8s.token
  sensitive = true
}

output "locality_region" {
  value = var.cluster_region
}

output "vpc_id" {
  value = module.gcp_base.vpc_id
}

output "project_id" {
  value = module.gcp_base.project_id
}