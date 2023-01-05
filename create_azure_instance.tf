resource "azurerm_resource_group" "create_rg" {
  count    = var.is_create_rg == true ? 1 : 0
  name     = var.resource_group_name
  location = var.region
}

data "azurerm_resource_group" "get_rg" {
  count = var.is_create_rg == false ? 1 : 0
  name  = var.resource_group_name
}

resource "random_password" "password" {
  length           = 10
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  numeric          = true
  special          = true
  override_special = "!@#$%"
}

resource "azurerm_virtual_machine" "create_azure_vm" {
  depends_on = [
    azurerm_network_interface.ANIC
  ]
  name                  = var.vm_name
  location              = var.region
  resource_group_name   = var.resource_group_name
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
    computer_name  = lower(var.vm_name)
    admin_username = lower(var.vm_name)
    admin_password = random_password.password.result
    custom_data    = local.custom_data
  }

  dynamic "os_profile_windows_config" {
    for_each = var.OS_name == "windows" && local.custom_data != null ? [1] : []
    content {
      provision_vm_agent = true
      winrm {
        protocol = "HTTP"
      }
      dynamic "additional_unattend_config" {
        for_each = local.additional_unattend_config
        content {
          pass         = additional_unattend_config.value["pass"]
          component    = additional_unattend_config.value["component"]
          setting_name = additional_unattend_config.value["setting_name"]
          content      = additional_unattend_config.value["content"]
        }
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

resource "time_sleep" "wait_60_seconds" {
  count           = var.OS_name == "windows" && local.custom_data != null && (var.user_data_file != null || var.user_data != null) ? 1 : 0
  depends_on      = [azurerm_virtual_machine.create_azure_vm]
  create_duration = "60s"
}

resource "null_resource" "provisioner" {
  count = var.OS_name == "windows" && local.custom_data != null && (var.user_data_file != null || var.user_data != null) ? 1 : 0
  depends_on = [
    time_sleep.wait_60_seconds
  ]
  connection {
    host     = azurerm_public_ip.public_ip.fqdn
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "2m"
    user     = lower(var.vm_name)
    password = random_password.password.result
  }

  provisioner "remote-exec" {
    script = var.user_data_file
  }
}

resource "azurerm_managed_disk" "create_disk" {
  count                = length(var.volume)
  name                 = "${var.vm_name}-adddisk${count.index}"
  location             = local.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.volume[count.index]
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_disk" {
  count              = length(var.volume)
  managed_disk_id    = azurerm_managed_disk.create_disk[count.index].id
  virtual_machine_id = azurerm_virtual_machine.create_azure_vm.id
  lun                = count.index
  caching            = "ReadWrite"
}