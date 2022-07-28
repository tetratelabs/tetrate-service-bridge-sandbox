resource "azurerm_resource_group" "tsb" {
  name     = "${var.name_prefix}_rg"
  location = var.location
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}

locals {
  subnet_prefixes = [for i in range(var.subnets_count) : "${cidrsubnet(var.cidr, 4, i)}"]
  subnet_names    = [for i in range(var.subnets_count) : "${var.name_prefix}_subnet${i}"]
}

module "vnet" {
  vnet_name           = "${var.name_prefix}_vnet"
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.tsb.name
  address_space       = [var.cidr]
  subnet_prefixes     = local.subnet_prefixes
  subnet_names        = local.subnet_names
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
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
  depends_on          = [azurerm_resource_group.tsb]
}

