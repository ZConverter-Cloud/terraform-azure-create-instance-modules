



# terraform-azure-create-instnace-modules
> Before You Begin
> 
> Prepare
> 
> Start Terraform
## Before You Begin
To successfully perform this tutorial, you must have the following:

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
	* **region**
	   -   [region list.](https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/#geographies) - Region name in Regions - ex : East US

##  Start Terraform

* To use terraform, you must have a terraform file of command written and a terraform executable.
* You should create a folder to use terraform, create a `terraform.tf` file, and enter the contents below.
	```
	#Define required providers
	terraform {
		required_providers {
			azurerm = {
				source = "hashicorp/azurerm"
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
				client_id = string
				client_secret = string
				tenant_id = string
				region = string
			})
			vm_info = object({
				vm_name = string
				vm_size = string
				resource_group = object({
					is_create = bool
					resource_group_name = string
				})
				OS = object({
					OS_name = string
					OS_version = string
				})
				network = object({
					virtual_network = object({
						is_create = bool
						azure_virtual_network_name = string
						AVN_address_space = optional(list(string),null)
					})
					subnet = object({
						is_create = bool
						subnet_name = string
						subnet_address_prefixes = optional(list(string),null)
					})
					nic_name = string
					security_group_rules = optional(list(object({
						name = optional(string,null)
					        direction = optional(string,null)
					        access = optional(string,null)
					        protocol = optional(string,null)
					        source_port_range = optional(string,null)
					        destination_port_range = optional(string,null)
					        source_address_prefix = optional(string,null)
					        destination_address_prefix = optional(string,null)
					})),[])
				})
				user_data = optional(string, null)
				user_data_file = optional(string, null)
				volume = optional(list(number), [])
			})
		})
		default  =  {
			provider = {
				client_id = null
				client_secret = null
				region = null
				subscription_id = null
				tenant_id = null
			}
			vm_info = {
				vm_size = null
				OS = {
					OS_name = null
					OS_version = null
				}
				network = {
					nic_name = null
					subnet = {
						is_create = false
						subnet_address_prefixes = []
						subnet_name = null
					}
					virtual_network = {
						AVN_address_space = []
						azure_virtual_network_name = null
						is_create = false
					}
					security_group_rules = [
						{
							name = null
							direction = null
							access = null
							protocol = null
							source_port_range = null
							destination_port_range = null
							source_address_prefix = null
							destination_address_prefix = null
						}
					]
				}
				resource_group = {
					is_create = false
					resource_group_name = null
				}
				user_data = null
				user_data_file = null
				vm_name = null
				volume = []
			}
		}
	}

	module  "azure" {
		source  =  "git::https://github.com/ZConverter-samples/terraform-azure-create-instnace-modules.git"
		vm_name  = var.terraform_data.vm_info.vm_name
		region  = var.terraform_data.provider.region
		vm_size  = var.terraform_data.vm_info.vm_size

		OS_name  = var.terraform_data.vm_info.OS.OS_name
		OS_version  = var.terraform_data.vm_info.OS.OS_version

		is_create_rg  = var.terraform_data.vm_info.resource_group.is_create
		resource_group_name  = var.terraform_data.vm_info.resource_group.resource_group_name

		is_create_VN  = var.terraform_data.vm_info.network.virtual_network.is_create
		AVN_name  = var.terraform_data.vm_info.network.virtual_network.azure_virtual_network_name
		AVN_address_space  = var.terraform_data.vm_info.network.virtual_network.AVN_address_space\
		
		is_create_subnet  = var.terraform_data.vm_info.network.subnet.is_create
		subnet_name  = var.terraform_data.vm_info.network.subnet.subnet_name
		subnet_address_prefixes  = var.terraform_data.vm_info.network.subnet.subnet_address_prefixes

		nic_name  = var.terraform_data.vm_info.network.nic_name
		security_group_rules  = var.terraform_data.vm_info.network.security_group_rules

		user_data  = var.terraform_data.vm_info.user_data
		user_data_file  = var.terraform_data.vm_info.user_data_file
		
		volume  = var.terraform_data.vm_info.volume
	}
   ```
* After creating the azure_terraform.json file to enter the user's value, you must enter the contents below. 
* ***The openstack_terraform.json below is an example of a required value only. See below the Attributes table for a complete example.***
* ***There is an attribute table for input values under the script, so you must refer to it.***
	```
	{
		"terraform_data" : {
			"provider" : {
				"subscription_id" : "********-****-****-****-************",
				"client_id" : "********-****-****-****-************",
				"client_secret" : "*******************************************************",
				"tenant_id" : "********-****-****-****-************",
				"region" : "Korea Central"
			},
			"vm_info" : {
				"vm_name" : "win2019",
				"vm_size" : "Standard_B2s",
				"resource_group" : {
					"is_create" : true,
					"resource_group_name" : "testtest"
				},
				"OS" : {
					"OS_name" : "windows",
					"OS_version" : "2019"
				},
				"network" : {
					"virtual_network" : {
						"is_create" : true,
						"azure_virtual_network_name" : "AVN-network",
						"AVN_address_space" : ["10.0.0.0/16"]
					},
					"subnet" : {
						"is_create" : true,
						"subnet_name" : "test-subnet",
						"subnet_address_prefixes" : ["10.0.1.0/24"]
					},
					"nic_name" : "test-nic",
					"security_group_rules" : [
						{
							"name" : "test1",
							"direction" : "Inbound",
							"access" : "Allow",
							"protocol" : "Tcp",
							"source_port_range" : "*",
							   "destination_port_range" : "50005-50006",
							   "source_address_prefix" : "*",
							"destination_address_prefix" : "*"
						},
						{
							"name" : "test2",
							"direction" : "Inbound",
							"access" : "Allow",
							"protocol" : "Tcp",
							"source_port_range" : "*",
						  "destination_port_range" : "3389",
						  "source_address_prefix" : "*",
							"destination_address_prefix" : "*"
						}
					]
				},
				"volume" : [30],
				"user_data_file" : "./test.ps1"
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
| terraform_data.vm_info.resource_group.is_create | string | yes | none |Specifies the name of the Virtual Machine.|
| terraform_data.vm_info.resource_group.resource_group_name | string | yes | none |Specifies the name of the Virtual Machine.|

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
   terraform apply -var-file=<Absolute path of azureterraform.json> -auto-approve
   ```
* **Note**
	* -auto-approve : Skips interactive approval of plan before applying. This option is ignored when you pass a previously-saved plan file, because Terraform considers you passing the plan file as the approval and so will never prompt in that case.
