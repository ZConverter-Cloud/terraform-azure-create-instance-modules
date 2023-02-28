output "result" {
    value = {
        IP = azurerm_public_ip.public_ip.ip_address,
        VM_NAME = var.vm_name,
        OS = "${var.OS_name}-${var.OS_version}"
    }
}
