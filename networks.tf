resource "azurerm_virtual_network" "create_AVN" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  count               = var.create_azure_virtual_network_name != null ? 1 : 0
  name                = var.create_azure_virtual_network_name
  address_space       = var.azure_virtual_network_address_space
  location            = local.location
  resource_group_name = local.rg_name
}

data "azurerm_virtual_network" "get_AVN" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  count               = var.azure_virtual_network_name != null ? 1 : 0
  name                = var.azure_virtual_network_name
  resource_group_name = local.rg_name
}

resource "azurerm_subnet" "create_internal" {
  depends_on = [
    azurerm_virtual_network.create_AVN,
    data.azurerm_virtual_network.get_AVN
  ]
  count                = var.create_subnet_name != null ? 1 : 0
  name                 = var.create_subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = var.create_azure_virtual_network_name != null ? var.create_azure_virtual_network_name : var.azure_virtual_network_name
  address_prefixes     = var.subnet_address_prefixes
}

data "azurerm_subnet" "get_internal" {
  depends_on = [
    azurerm_virtual_network.create_AVN,
    data.azurerm_virtual_network.get_AVN
  ]
  count                = var.subnet_name != null ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.create_azure_virtual_network_name != null ? var.create_azure_virtual_network_name : var.azure_virtual_network_name
  resource_group_name  = local.rg_name
}

resource "azurerm_public_ip" "public_ip" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  name                = "${var.vm_name}-PublicIp"
  resource_group_name = local.rg_name
  location            = local.location
  allocation_method   = "Static"
  domain_name_label   = "${var.vm_name}-${lower(substr("${join("", split(":", timestamp()))}", 8, -1))}"
}

resource "azurerm_network_interface" "ANIC" {
  depends_on = [
    azurerm_subnet.create_internal,
    data.azurerm_subnet.get_internal,
    azurerm_public_ip.public_ip
  ]
  name                = "${var.vm_name}-ANIC"
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "${var.vm_name}-ANIC"
    subnet_id                     = var.create_subnet_name != null ? azurerm_subnet.create_internal[0].id : data.azurerm_subnet.get_internal[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "security_group" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  name                = "${var.vm_name}-nsg"
  location            = local.location
  resource_group_name = local.rg_name
}

resource "azurerm_network_interface_security_group_association" "security_group_attach" {
  depends_on = [
    azurerm_network_interface.ANIC,
    azurerm_network_security_group.security_group
  ]
  network_interface_id      = azurerm_network_interface.ANIC.id
  network_security_group_id = azurerm_network_security_group.security_group.id
}

resource "azurerm_network_security_rule" "connection_port" {
  count                       = length(var.create_security_group_rules)
  depends_on                  = [azurerm_resource_group.create_rg]
  name                        = "${var.vm_name}-${var.create_security_group_rules[count.index].direction}-${var.create_security_group_rules[count.index].port_range_min}-${var.create_security_group_rules[count.index].port_range_max}"
  priority                    = (200 + (count.index * 10))
  direction                   = var.create_security_group_rules[count.index].direction == "Inbound" || var.create_security_group_rules[count.index].direction == "ingress" ? "Inbound" : var.create_security_group_rules[count.index].direction == "egress" || var.create_security_group_rules[count.index].direction == "Outbound" ? "Outbound" : null
  access                      = "Allow"
  protocol                    = title(lower(var.create_security_group_rules[count.index].protocol))
  source_port_range           = "*"
  destination_port_range      = "${var.create_security_group_rules[count.index].port_range_min == var.create_security_group_rules[count.index].port_range_max ? var.create_security_group_rules[count.index].port_range_min : "${var.create_security_group_rules[count.index].port_range_min}-${var.create_security_group_rules[count.index].port_range_max}"}"
  source_address_prefix       = "*"
  destination_address_prefix  = var.create_security_group_rules[count.index].remote_ip_prefix
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}
