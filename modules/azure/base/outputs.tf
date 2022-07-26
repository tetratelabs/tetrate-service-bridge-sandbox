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
  value = "${var.name_prefix}_resource_group"
}

output "registry" {
  value = azurerm_container_registry.acr.login_server
}

output "registry_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "registry_password" {
  value = azurerm_container_registry.acr.admin_password
}

output "registry_id" {
  value = azurerm_container_registry.acr.id
}

output "cidr" {
  value = var.cidr
}
