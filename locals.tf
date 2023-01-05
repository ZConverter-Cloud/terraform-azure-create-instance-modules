locals {
  os = {
    "ubuntu" : {
      "publisher" : "Canonical",
      "offer" : "UbuntuServer",
      "sku" : "${var.OS_version}-LTS"
    },
    "windows" : {
      "publisher" : "MicrosoftWindowsServer",
      "offer" : "WindowsServer",
      "sku" : "${var.OS_version}-Datacenter-gensecond"
    },
    "centos" : {
      "publisher" : "OpenLogic",
      "offer" : "CentOS",
      "sku" : "${var.OS_version}"
    }
  }
  location    = var.is_create_rg == true ? azurerm_resource_group.create_rg[0].location : data.azurerm_resource_group.get_rg[0].location
  rg_name     = var.is_create_rg == true ? azurerm_resource_group.create_rg[0].name : data.azurerm_resource_group.get_rg[0].name
  custom_data = var.user_data_file != null ? fileexists(var.user_data_file) == true ? base64encode(local.winrm_script) : null : var.user_data != null ? base64encode(local.winrm_script) : null
  winrm_security_group = [
    {
      name                       = "winrm"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5985-5986"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

locals {
  additional_unattend_config = [
    {
      # Auto-Login's required to configure WinRM
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${random_password.password.result}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${lower(var.vm_name)}</Username></AutoLogon>"
    },
    {
      # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = <<EOT
<FirstLogonCommands>
    <SynchronousCommand>
        <CommandLine>cmd /c "mkdir C:\terraform"</CommandLine>
        <Description>Create the Terraform working directory</Description>
        <Order>11</Order>
    </SynchronousCommand>
    <SynchronousCommand>
        <CommandLine>cmd /c "copy C:\AzureData\CustomData.bin C:\terraform\winrm.ps1"</CommandLine>
        <Description>Move the CustomData file to the working directory</Description>
        <Order>12</Order>
    </SynchronousCommand>
    <SynchronousCommand>
        <CommandLine>powershell.exe -sta -ExecutionPolicy Unrestricted -file C:\terraform\winrm.ps1</CommandLine>
        <Description>Execute the WinRM enabling script</Description>
        <Order>13</Order>
    </SynchronousCommand>
</FirstLogonCommands>
EOT
    }
  ]
  winrm_script = <<EOT
Write-Host "Delete any existing WinRM listeners"
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

Write-Host "Create a new WinRM listener and configure"
winrm create winrm/config/listener?Address=*+Transport=HTTP
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

Write-Host "Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

Write-Host "turn off PowerShell execution policy restrictions"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Host "Configure and restart the WinRM Service; Enable the required firewall exception"
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
Start-Service -Name WinRM
EOT
}