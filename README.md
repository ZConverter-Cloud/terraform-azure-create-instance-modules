# terraform-azure-create-instnace-modules
> Before You Begin
> 
> Prepare
> 
> Start Terraform

## Before You Begin
To successfully perform this tutorial, you must have the following:
* You need to install [git](https://git-scm.com/downloads) in advance to use it.
* Only CentOS, Ubuntu, and Windows are available for operating systems, and [OS versions with cloud initialization](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init) are recommended.
	* Windows does not have to consider cloud-init when selecting the os version.

## Prepare
Prepare your environment for authenticating and running your Terraform scripts. Also, gather the information your account needs to authenticate the scripts.

### Install Terraform
   Install the latest version of Terraform **v1.3.0+**:

   1. In your environment, check your Terraform version.
      ```script
      terraform -v
      ```

      If you don't have Terraform **v1.3.0+**, then install Terraform using the following steps.

   2. From a browser, go to [Download Latest Terraform Release](https://www.terraform.io/downloads.html).

   3. Find the link for your environment and then follow the instructions for your environment. Alternatively, you can perform the following steps. Here is an example for installing Terraform v1.3.3 on Linux 64-bit.

   4. In your environment, create a temp directory and change to that directory:
      ```script
      mkdir temp
      ```
      ```script
      cd temp
      ```

   5. Download the Terraform zip file. Example:
      ```script
      wget https://releases.hashicorp.com/terraform/1.3.3/terraform_1.3.3_linux_amd64.zip
      ```

   6. Unzip the file. Example:
      ```script
      unzip terraform_1.3.3_linux_amd64.zip
      ```

   7. Move the folder to /usr/local/bin or its equivalent in Mac. Example:
      ```script
      sudo mv terraform /usr/local/bin
      ```

   8. Go back to your home directory:
      ```script
      cd
      ```

   9. Check the Terraform version:
      ```script
      terraform -v
      ```

      Example: `Terraform v1.3.3 on linux_amd64`.

### Get API-Key

**In order to use azure terraform, a service organizer must be created on your account.**
   We need the provider information below to use the azure terraform.
   * **subscription_id**
	   - [Find your Azure subscription.](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription)
   * **tenant_id**
	   - [Find your Azure AD tenant.](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-ad-tenant)
   * **client_id, client_secret**
	   -   [Please refer to the guide.](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#creating-a-service-principal-using-the-azure-cli)

##  Start Terraform

* To use terraform, you must have a terraform file of command written and a terraform executable.
* You should create a folder to use terraform, create a `terraform.tf` file, and enter the contents below.
	```
	# Define required providers
	terraform {
		required_providers {
			azurerm = {
				source  = "hashicorp/azurerm"
				version = "3.33.0"
			}
		}
	}

	provider "azurerm" {
		features {}
		subscription_id = var.terraform_data.provider.subscription_id
		client_id = var.terraform_data.provider.client_id
		client_secret = var.terraform_data.provider.client_secret
		tenant_id = var.terraform_data.provider.tenant_id
	}

	variable "terraform_data" {
		type = object({
			provider = object({
				subscription_id = string
				client_id       = string
				client_secret   = string
				tenant_id       = string
				region          = string
			})
			vm_info = object({
				vm_name        = string
				vm_size        = string
				vm_password      = string
				resource_group = object({
					is_create              = bool
					resource_group_name   = string
				})
				OS = object({
					OS_name    = string
					OS_version = string
				})
				network_interface = object({
					virtual_network = object({
						is_create                 = bool
						azure_virtual_network_name = string
						AVN_address_space         = list(string)
					})
					subnet = object({
						is_create              = bool
						subnet_name            = string
						subnet_address_prefixes = list(string)
					})
					nic_name               = string
					security_group_rules   = optional(list(object({
						direction        = string
						protocol         = string
						port_range_min   = string
						port_range_max   = string
						remote_ip_prefix = string
					})),[])
				})
				user_data           = optional(string, null)
				user_data_file_path = optional(string, null)
				volume              = optional(list(number), [])
			})
		})
	}

	locals {
		resource_group_name = var.terraform_data.vm_info.resource_group.is_create == false ? var.terraform_data.vm_info.resource_group.resource_group_name : null
		create_resource_group_name = var.terraform_data.vm_info.resource_group.is_create == true ? var.terraform_data.vm_info.resource_group.resource_group_name : null

		azure_virtual_network_name = var.terraform_data.vm_info.network_interface.virtual_network.is_create == false ? var.terraform_data.vm_info.network_interface.virtual_network.azure_virtual_network_name : null
		create_azure_virtual_network_name = var.terraform_data.vm_info.network_interface.virtual_network.is_create == true ? var.terraform_data.vm_info.network_interface.virtual_network.create_azure_virtual_network_name : null

		subnet_name = var.terraform_data.vm_info.network_interface.subnet.is_create == false ? var.terraform_data.vm_info.network_interface.subnet.subnet_name : null
		create_subnet_name = var.terraform_data.vm_info.network_interface.subnet.is_create == true ? var.terraform_data.vm_info.network_interface.subnet.create_subnet_name : null
	}

	module  "create_azure_instance" {
		source = "git::https://github.com/ZConverter-Cloud/terraform-azure-create-instance-modules.git"
		region = var.terraform_data.provider.region

		vm_name = var.terraform_data.vm_info.vm_name
		vm_size = var.terraform_data.vm_info.vm_size
		vm_password = var.terraform_data.vm_info.vm_password
		
		resource_group_name = local.resource_group_name
		create_resource_group_name = local.create_resource_group_name
		
		OS_name = var.terraform_data.vm_info.OS.OS_name
		OS_version = var.terraform_data.vm_info.OS.OS_version

		azure_virtual_network_name = local.azure_virtual_network_name
		create_azure_virtual_network_name = local.create_azure_virtual_network_name
		azure_virtual_network_address_space = var.terraform_data.vm_info.network_interface.virtual_network.AVN_address_space

		subnet_name = local.subnet_name
		create_subnet_name = local.create_subnet_name
		subnet_address_prefixes = var.terraform_data.vm_info.network_interface.subnet.subnet_address_prefixes

		create_security_group_rules = var.terraform_data.vm_info.network_interface.security_group_rules

		user_data_file_path = var.terraform_data.vm_info.user_data_file_path
		additional_volumes = var.terraform_data.vm_info.volume
	}

        output "result" {
                value = module.create_azure_instance.result
        }
   ```
* After creating the azure_terraform.json file to enter the user's value, you must enter the contents below. 
* ***The openstack_terraform.json below is an example of a required value only. See below the Attributes table for a complete example.***
* ***There is an attribute table for input values under the script, so you must refer to it.***
	```
	{
		"terraform_data": {
			"provider": {
				"subscription_id": "93229549-****-****-****-************",
				"client_id": "3023e61a-****-****-****-************",
				"client_secret": "IVo8Q~************************************",
				"tenant_id": "f79bb0dc-****-****-****-************",
				"region": "Korea South"
			},
			"vm_info": {
				"vm_name": "terraform-test",
				"vm_size": "Standard_D1",
				"vm_password" : "**********",
				"resource_group": {
					"is_create": false,
					"resource_group_name": "test"
				},
				"OS": {
					"OS_name": "centos",
					"OS_version": "7.9"
				},
				"network_interface": {
					"virtual_network": {
						"is_create": false,
						"azure_virtual_network_name": "test-vnet",
						"AVN_address_space": [
							"10.0.0.0/16"
						]
					},
					"subnet": {
						"is_create": false,
						"subnet_name": "default",
						"subnet_address_prefixes": [
							"10.0.1.0/24"
						]
					},
					"nic_name": "test85",
					"security_group_rules": [
						{
							"direction"        : "Inbound",
							"protocol"         : "tcp",
							"port_range_min"   : "22",
							"port_range_max"   : "22",
							"remote_ip_prefix" : "0.0.0.0/0"
						}
					]
				},
				"user_data_file_path": "./user_data.sh",
				"volume": [
					30
				]
			}
		}
	}
	```
### Attribute Table
|Attribute|Data Type|Required|Default Value|Description|
|---------|---------|--------|-------------|-----------|
| terraform_data.provider.subscription_id | string | yes | none |Subscription ID found through the [preparation step](#get-api-key).|
| terraform_data.provider.client_id | string | yes | none |Client ID found through the [preparation step](#get-api-key).|
| terraform_data.provider.client_secret | string | yes | none |Client Secret found through the [preparation step](#get-api-key).|
| terraform_data.provider.tenant_id | string | yes | none |Tenant ID found through the [preparation step](#get-api-key).|
| terraform_data.provider.region | string | yes | none |Region Name found through the [preparation step](#get-api-key).|
| terraform_data.vm_info.vm_name | string | yes | none |Specifies the name of the Virtual Machine.|
| terraform_data.vm_info.vm_size | string | yes | none | Specifies the [size of the Virtual Machine](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-general). See also [Azure VM Naming Conventions](https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions). |
| terraform_data.vm_info.resource_group.is_create | boolean | yes | none | True to create resource_group, false if not. |
| terraform_data.vm_info.resource_group.resource_group_name | string | yes | none |Specifies the name of the Resource Group.|
| terraform_data.vm_info.OS.OS_name | string | yes | none |You can enter either `ubuntu`, `centos`, or `windows`.|
| terraform_data.vm_info.OS.OS_version | string | yes | none |Enter os version with reference to [preparation step](#before-you-begin)|
| terraform_data.vm_info.network.virtual_network.is_create | string | yes | none |True to create Virtual Network, false if not.|
| terraform_data.vm_info.network.virtual_network.azure_virtual_network_name | string | yes | none |Specifies the name of the Azure Virtual Network.|
| terraform_data.vm_info.network.virtual_network.AVN_address_space | list(string) | conditional | none |CIDR (ex : `["10.0.0.0/16"]`)|
| terraform_data.vm_info.network.subnet.is_create | boolean | yes | none | True to create subnet, false if not. |
| terraform_data.vm_info.network.subnet.subnet_name | string | yes | none |Specifies the name of the Subnet.|
| terraform_data.vm_info.network.subnet.subnet_address_prefixes | list(string) | conditional | none |CIDR (ex : `["10.0.1.0/24"]`)|
| terraform_data.vm_info.network.nic_name | string | conditional | none | Specifies the name of the Network Interface. |
| terraform_data.vm_info.network.security_group_rules[*].direction | string | conditional | none | The direction specifies if rule will be evaluated on incoming or outgoing traffic. Possible values are `Inbound` and `Outbound`. |
| terraform_data.vm_info.network.security_group_rules[*].protocol | string | conditional | none | Network protocol this rule applies to. Possible values include Tcp, Udp, Icmp, Esp, Ah or * (which matches all). |
| terraform_data.vm_info.network.security_group_rules[*].port_range_min | string | conditional | none | Minimum port range, type the same port in port_range_max to allow only one port |
| terraform_data.vm_info.network.security_group_rules[*].port_range_max | string | conditional | none | Maximum port range, enter the same port as port_range_min to allow only one port |
| terraform_data.vm_info.network.security_group_rules[*].remote_ip_prefix | string | conditional | none | CIDR or destination IP range or * to match any IP. Tags such as ‘VirtualNetwork’, ‘AzureLoadBalancer’ and ‘Internet’ can also be used. Besides, it also supports all available Service Tags like ‘Sql.WestEurope‘, ‘Storage.EastUS‘, etc. |
| terraform_data.vm_info.user_data | string | yes | none | user_data_script |
| terraform_data.vm_info.user_data_file | string | yes | none | Absolute path of user data file path to use when cloud-init. |
| terraform_data.vm_info.volume | string | yes | none | Use to add a block volume. Use numeric arrays. |



* **Go to the file path of Terraform.exe and Initialize the working directory containing the terraform configuration file.**

   ```
   terraform init
   ```
   * **Note**
       -chdir : When you use a chdir the usual way to run Terraform is to first switch to the directory containing the `.tf` files for your root module (for example, using the `cd` command), so that Terraform will find those files automatically without any extra arguments. (ex : terraform -chdir=\<terraform data file path\> init)

* **Creates an execution plan. By default, creating a plan consists of:**
  * Reading the current state of any already-existing remote objects to make sure that the Terraform state is up-to-date.
  * Comparing the current configuration to the prior state and noting any differences.
  * Proposing a set of change actions that should, if applied, make the remote objects match the configuration.
   ```
   terraform plan -var-file=<Absolute path of azure_terraform.json>
   ```
  * **Note**
	* -var-file : When you use a var-file Sets values for potentially many [input variables](https://www.terraform.io/docs/language/values/variables.html) declared in the root module of the configuration, using definitions from a ["tfvars" file](https://www.terraform.io/docs/language/values/variables.html#variable-definitions-tfvars-files). Use this option multiple times to include values from more than one file.
     * The file name of vars.tfvars can be changed.

* **Executes the actions proposed in a Terraform plan.**
   ```
   terraform apply -var-file=<Absolute path of azure_terraform.json> -auto-approve
   ```
* **Note**
	* -auto-approve : Skips interactive approval of plan before applying. This option is ignored when you pass a previously-saved plan file, because Terraform considers you passing the plan file as the approval and so will never prompt in that case.
