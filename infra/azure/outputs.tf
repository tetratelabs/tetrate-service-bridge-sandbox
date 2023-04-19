output "registry" {
  value = module.azure_base[0].registry
}

output "registry_username" {
  value = module.azure_base[0].registry_username
}

output "registry_password" {
  value = module.azure_base[0].registry_password
  sensitive = true
}

output "public_ip" {
  value = module.azure_jumpbox[0].public_ip
}

output "pkey" {
  value     = module.azure_jumpbox[0].pkey
  sensitive = true
}

output "cluster_name" {
  value = module.azure_k8s[0].cluster_name
}

output "host" {
  value     = module.azure_k8s[0].host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.azure_k8s[0].cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.azure_k8s[0].token
  sensitive = true
}

output "locality_region" {
  value = var.azure_k8s_region
}
output "vnet_id" {
  value = module.azure_base[0].vnet_id
}

output "kubelet_identity" {
  value = module.azure_k8s[0].kubelet_identity 
}

output "resource_group_name" {
  value = module.azure_base[0].resource_group_name
}

output "resource_group_id" {
  value = module.azure_base[0].resource_group_id
}