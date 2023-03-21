resource "azurerm_virtual_machine" "create_azure_vm" {
  name                  = var.vm_name
  location              = local.location
  resource_group_name   = local.rg_name
  network_interface_ids = formatlist(azurerm_network_interface.ANIC.id)
  vm_size               = var.vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = local.os[var.OS_name]["publisher"]
    offer     = local.os[var.OS_name]["offer"]
    sku       = local.os[var.OS_name]["sku"]
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.vm_name}-BootDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = var.vm_name
    admin_username = var.vm_name
    admin_password = var.vm_password
    custom_data    = local.custom_data
  }

  dynamic "os_profile_windows_config" {
    for_each = var.OS_name == "windows" ? [1] : []
    content {
      provision_vm_agent = true
      winrm {
        protocol = "HTTP"
      }
    }
  }

  dynamic "os_profile_linux_config" {
    for_each = var.OS_name != "windows" ? [1] : []
    content {
      disable_password_authentication = false
    }
  }
}

resource "azurerm_virtual_machine_extension" "example_extension" {
  depends_on = [
    azurerm_virtual_machine.create_azure_vm
  ]
  count = var.OS_name == "windows" ? 1 : 0
  name                 = "example_extension"
  virtual_machine_id   = azurerm_virtual_machine.create_azure_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
      "commandToExecute": "cd C:\\ && cmd.exe /c move %SYSTEMDRIVE%\\AzureData\\CustomData.bin C:\\userscript.cmd && start /k cmd.exe /C C:\\userscript.cmd 2>&1 || true;"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {}
  PROTECTED_SETTINGS
}
