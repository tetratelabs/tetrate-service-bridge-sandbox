output "registry" {
  value = module.gcp_ocp_base[0].registry
}

output "registry_username" {
  value = module.gcp_ocp_base[0].registry_username
}

output "registry_password" {
  value = module.gcp_ocp_base[0].registry_password
  sensitive = true
}

output "public_ip" {
  value = module.gcp_ocp_jumpbox[0].public_ip
}

output "pkey" {
  value     = module.gcp_ocp_jumpbox[0].pkey
  sensitive = true
}

output "cluster_name" {
  value = module.gcp_ocp_jumpbox[0].cluster_name
}

# output "host" {
#   value     = module.gcp_ocp_jumpbox[0].host
#   sensitive = true
# }

# output "cluster_ca_certificate" {
#   value     = module.gcp_ocp_jumpbox[0].cluster_ca_certificate
#   sensitive = true
# }

# output "token" {
#   value     = module.gcp_ocp_jumpbox[0].token
#   sensitive = true
# }

output "locality_region" {
  value = var.gcp_ocp_region
}

output "vpc_id" {
  value = module.gcp_ocp_base[0].vpc_id
}

output "project_id" {
  value = module.gcp_ocp_base[0].project_id
}