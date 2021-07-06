resource "azurerm_resource_group" "tsb" {
  name     = "${var.name_prefix}_resource_group"
  location = var.location
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}

module "vnet" {
  vnet_name                = "${var.name_prefix}_vnet"
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.tsb.name
  address_space       = [ var.cidr ]
  subnet_prefixes     = [ cidrsubnet(var.cidr, 8, 1), cidrsubnet(var.cidr, 8, 2), cidrsubnet(var.cidr, 8, 3 )]
  subnet_names        = ["${var.name_prefix}_subnet1", "${var.name_prefix}_subnet2", "${var.name_prefix}_subnet3"]
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
  depends_on = [ azurerm_resource_group.tsb ]
}

resource "random_string" "random" {
  length           = 16
  special          = false
  lower            = true
}

resource "azurerm_container_registry" "acr" {
  name                     = "${var.name_prefix}tsbacr${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.tsb.name
  location                 = var.location
  sku                      = "Premium"
  admin_enabled            = true
  depends_on = [ azurerm_resource_group.tsb ]
}

