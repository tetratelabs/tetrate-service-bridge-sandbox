output "vnet_name" {
  value = module.vnet.vnet_name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "vnet_subnets" {
  value = module.vnet.vnet_subnets
}

output "resource_group_name" {
  value = azurerm_resource_group.tsb.name
}

output "resource_group_id" {
  value = azurerm_resource_group.tsb.id
}

output "registry" {
  value = azurerm_container_registry.acr.login_server
}

output "registry_id" {
  value = azurerm_container_registry.acr.id
}
output "registry_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "registry_password" {
  value = azurerm_container_registry.acr.admin_password
}

output "cidr" {
  value = var.cidr
}
