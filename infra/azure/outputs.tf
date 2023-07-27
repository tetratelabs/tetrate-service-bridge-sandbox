output "registry" {
  value = module.azure_base.registry
}

output "registry_username" {
  value = module.azure_base.registry_username
}

output "registry_password" {
  value     = module.azure_base.registry_password
  sensitive = true
}

output "public_ip" {
  value = module.azure_jumpbox.public_ip
}

output "pkey" {
  value     = module.azure_jumpbox.pkey
  sensitive = true
}

output "cluster_name" {
  value = module.azure_k8s.cluster_name
}

output "host" {
  value     = module.azure_k8s.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.azure_k8s.cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.azure_k8s.token
  sensitive = true
}

output "locality_region" {
  value = var.azure_k8s_region
}
output "vnet_id" {
  value = module.azure_base.vnet_id
}

output "kubelet_identity" {
  value = module.azure_k8s.kubelet_identity
}

output "resource_group_name" {
  value = module.azure_base.resource_group_name
}

output "resource_group_id" {
  value = module.azure_base.resource_group_id
}