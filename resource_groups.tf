resource "azurerm_resource_group" "create_rg" {
  count    = var.create_resource_group_name != null ? 1 : 0
  name     = var.create_resource_group_name
  location = var.region
}

data "azurerm_resource_group" "get_rg" {
  count = var.resource_group_name != null ? 1 : 0
  name  = var.resource_group_name
}
