resource "random_string" "random_prefix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}
resource "azurerm_resource_group" "tsb" {
  name     = "${var.name_prefix}-${random_string.random_prefix.result}_rg"
  location = var.location
  tags = merge(var.tags, {
    Name            = "${var.name_prefix}-${random_string.random_prefix.result}_rg"
  })
}

locals {
  subnet_prefixes = [for i in range(var.subnets_count) : "${cidrsubnet(var.cidr, 4, i)}"]
  subnet_names    = [for i in range(var.subnets_count) : "${var.name_prefix}_subnet${i}"]
}

module "vnet" {
  vnet_name           = "${var.name_prefix}_vnet"
  source              = "Azure/vnet/azurerm"
  vnet_location       = var.location
  use_for_each        = false
  resource_group_name = azurerm_resource_group.tsb.name
  address_space       = [var.cidr]
  subnet_prefixes     = local.subnet_prefixes
  subnet_names        = local.subnet_names
  tags = merge(var.tags, {
    Name            = "${var.name_prefix}_vnet"
  })
  depends_on = [azurerm_resource_group.tsb]
}

resource "random_string" "random" {
  length  = 16
  special = false
  lower   = true
}

resource "azurerm_container_registry" "acr" {
  name                = replace("${var.name_prefix}tsbacr${random_string.random.result}", "-", "")
  resource_group_name = azurerm_resource_group.tsb.name
  location            = var.location
  sku                 = "Premium"
  admin_enabled       = true
  tags = merge(var.tags, {
    Name            = replace("${var.name_prefix}tsbacr${random_string.random.result}", "-", "")
  })
  depends_on          = [azurerm_resource_group.tsb]
}

