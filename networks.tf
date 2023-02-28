resource "azurerm_virtual_network" "create_AVN" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  count               = var.is_create_VN == true ? 1 : 0
  name                = var.AVN_name
  address_space       = var.AVN_address_space
  location            = local.location
  resource_group_name = local.rg_name
}

data "azurerm_virtual_network" "get_AVN" {
  depends_on = [
    azurerm_resource_group.create_rg,
    data.azurerm_resource_group.get_rg
  ]
  count               = var.is_create_VN == false ? 1 : 0
  name                = var.AVN_name
  resource_group_name = local.rg_name
}

resource "azurerm_subnet" "create_internal" {
  depends_on = [
    azurerm_virtual_network.create_AVN,
    data.azurerm_virtual_network.get_AVN
  ]
  count                = var.is_create_subnet == true ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = local.rg_name
  virtual_network_name = var.AVN_name
  address_prefixes     = var.subnet_address_prefixes
}

data "azurerm_subnet" "get_internal" {
  depends_on = [
    azurerm_virtual_network.create_AVN,
    data.azurerm_virtual_network.get_AVN
  ]
  count                = var.is_create_subnet == false ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.AVN_name
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
  name                = var.nic_name
  location            = local.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = var.nic_name
    subnet_id                     = var.is_create_subnet == true ? azurerm_subnet.create_internal[0].id : data.azurerm_subnet.get_internal[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "security_group" {
  name                = "${var.vm_name}-nsg"
  location            = local.location
  resource_group_name = local.rg_name
}

resource "azurerm_network_interface_security_group_association" "security_group_attach" {
  network_interface_id      = azurerm_network_interface.ANIC.id
  network_security_group_id = azurerm_network_security_group.security_group.id
}

resource "azurerm_network_security_rule" "winrm" {
  count                       = var.user_data_file != null ? length(local.winrm_security_group) : 0
  depends_on                  = [azurerm_resource_group.create_rg]
  name                        = local.winrm_security_group[count.index].name
  priority                    = local.winrm_security_group[count.index].priority
  direction                   = local.winrm_security_group[count.index].direction
  access                      = local.winrm_security_group[count.index].access
  protocol                    = local.winrm_security_group[count.index].protocol
  source_port_range           = local.winrm_security_group[count.index].source_port_range
  destination_port_range      = local.winrm_security_group[count.index].destination_port_range
  source_address_prefix       = local.winrm_security_group[count.index].source_address_prefix
  destination_address_prefix  = local.winrm_security_group[count.index].destination_address_prefix
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}

resource "azurerm_network_security_rule" "connection_port" {
  count                       = length(var.security_group_rules)
  depends_on                  = [azurerm_resource_group.create_rg]
  name                        = "${var.vm_name}-${var.security_group_rules[count.index].direction}-${var.security_group_rules[count.index].port_range_min}-${var.security_group_rules[count.index].port_range_max}"
  priority                    = (200 + (count.index * 10))
  direction                   = var.security_group_rules[count.index].direction
  access                      = "Allow"
  protocol                    = title(lower(var.security_group_rules[count.index].protocol))
  source_port_range           = "*"
  destination_port_range      = "${var.var.security_group_rules[count.index].port_range_min == var.var.security_group_rules[count.index].port_range_max ? var.var.security_group_rules[count.index].port_range_min : "${var.var.security_group_rules[count.index].port_range_min}-${var.var.security_group_rules[count.index].port_range_max}"}"
  source_address_prefix       = ["*"]
  destination_address_prefix  = var.security_group_rules[count.index].remote_ip_prefix
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.security_group.name
}
