terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.33.0"
    }
  }
}

variable "region" {
  type    = string
  default = null
}

variable "vm_name" {
  type = string
}

variable "vm_password" {
  type = string
}

variable "resource_group_name" {
  type    = string
  default = null
}

variable "create_resource_group_name" {
  type    = string
  default = null
}

variable "OS_name" {
  type = string
}

variable "OS_version" {
  type = string
}

variable "azure_virtual_network_name" {
  type    = string
  default = null
}

variable "create_azure_virtual_network_name" {
  type    = string
  default = null
}

variable "azure_virtual_network_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_name" {
  type    = string
  default = null
}

variable "create_subnet_name" {
  type    = string
  default = null
}

variable "subnet_address_prefixes" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "vm_size" {
  type = string
}

variable "user_data_file_path" {
  type    = string
  default = null
}

variable "additional_volumes" {
  type    = list(number)
  default = []
}

variable "create_security_group_rules" {
  type = list(object({
    direction        = string
    protocol         = string
    port_range_min   = string
    port_range_max   = string
    remote_ip_prefix = string
  }))
  default = []
}
