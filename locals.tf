locals {
  centVersion = var.OS_version == "7.8" || var.OS_version == "7.9" || var.OS_version == "8.1" || var.OS_version == "8.2" || var.OS_version == "8.3" ? replace(var.OS_version,".","_") : var.OS_version
  os = {
    "ubuntu" : {
      "publisher" : "Canonical",
      "offer" : var.OS_version == "20.04" ? "0001-com-ubuntu-server-focal" : var.OS_version == "22.04" ? "0001-com-ubuntu-server-jammy" : "UbuntuServer",
      "sku" : "${var.OS_version != "18.04" ? replace(var.OS_version,".","_") : var.OS_version}-${var.OS_version == "18.04" ? "LTS" : "lts"}"
    },
    "windows" : {
      "publisher" : "MicrosoftWindowsServer",
      "offer" : "WindowsServer",
      "sku" : "${var.OS_version == "2012" ? "2012-R2" : var.OS_version}-Datacenter-gensecond"
    },
    "centos" : {
      "publisher" : "OpenLogic",
      "offer" : "CentOS",
      "sku" : "${local.centVersion}"
    }
  }
  location = var.create_resource_group_name != null ? azurerm_resource_group.create_rg[0].location : data.azurerm_resource_group.get_rg[0].location
  rg_name  = var.create_resource_group_name != null ? azurerm_resource_group.create_rg[0].name : data.azurerm_resource_group.get_rg[0].name
  custom_data = var.user_data_file_path != null ? fileexists(var.user_data_file_path) != false ? base64encode(replace(replace(file(var.user_data_file_path),"<script>",""),"</script>","")) : null : null
}
