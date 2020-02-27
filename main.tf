# All resources and attributes names
# Use only in the name attributes of its own, not at other resources name references
locals {
  rg_name                        = "${var.env}-rg" //"${local.wafgw_name}-rg"
  net_name                       = "${var.env}-vnet"
  snet_name                      = "${var.env}-snet"
}


resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags = {
    env = var.env
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.net_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = [var.vnet_range]
  tags = {
    environment = var.env
  }
}

resource "azurerm_subnet" "snet" {
  name                 = local.snet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = var.snet_range
}