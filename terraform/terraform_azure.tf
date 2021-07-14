## Ensures 2.0+ of the azurevm provider to get the azurerm_windows_virtual_machine resource and
## the other resources and capabilities
provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}

##getting the read-only resource from azure about the resource group
## Create an Azure resource group using the value of resource_group and the location of the location variable
## defined in the terraform.tfvars file built by Ansible.
resource "azurerm_resource_group" "terraform-RG" {
  name     = "terraform-resource"
  location = var.location
}


## Create a simple vNet
resource "azurerm_virtual_network" "main" {
  name                = "terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.terraform-RG.location
  resource_group_name = azurerm_resource_group.terraform-RG.name
}

## Create a simple subnet for VMs inside of the vNet ensuring the VNet is created first (depends_on)
resource "azurerm_subnet" "internal" {
  name                 = "terraform-Subnet"
  resource_group_name  = azurerm_resource_group.terraform-RG.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"

  depends_on = [
    azurerm_virtual_network.main
  ]
}
## Create an availability set called test_AS which the VM will go into using the same location and resource
## group
resource "azurerm_availability_set" "test_AS" {
  name                = "terraform-AS"
  location            = azurerm_resource_group.terraform-RG.location
  resource_group_name = azurerm_resource_group.terraform-RG.name
}



## Create an Azure NSG from already existing nsg passed from tfvars to protect the infrastructure called my_nsg.
resource "azurerm_network_security_group" "my_nsg" {
  name                = "terraform-nsg"
  location            = azurerm_resource_group.terraform-RG.location
  resource_group_name = azurerm_resource_group.terraform-RG.name
  
  ## Create a rule to allow k8s to connect to VM 
  security_rule {
    name                       = "allowk8s"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  
  ## Create a rule to allow Ansible to connect to each linux VM from your local linux Shell by SSH
  ## You'll pass the value of the variables to the plan when invoking it. This locks down "SSH"
  ## to your local public IP address.
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}






## You'll need public IPs for each VM for Ansible to connect to and to deploy the web app to.
resource "azurerm_public_ip" "vmIps" {
  count                   = var.VM_number
  name                    = "terraform-${count.index}"
  location                = azurerm_resource_group.terraform-RG.location
  resource_group_name     = azurerm_resource_group.terraform-RG.name
  allocation_method       = "Dynamic"
}

## Create a vNic for each windows VM. Using the count property to create two vNIcs while using ${count.index}
## to refer to each VM which will be defined in an array
resource "azurerm_network_interface" "main" {
  count               = var.VM_number
  name                = "terraform-NIC-${count.index}"
  location            = azurerm_resource_group.terraform-RG.location
  resource_group_name = azurerm_resource_group.terraform-RG.name
  
  ## Simple ip configuration for each vNic
  ip_configuration {
    name                          = "terraform-ip_config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmIps[count.index].id
  }
  
  ## Ensure the subnet is created first before creating these vNics.
  depends_on = [
    azurerm_subnet.internal
  ]
}




## Apply the NSG to each of the linux VMs' NICs
resource "azurerm_network_interface_security_group_association" "linuxnsg" {
  count                     = var.VM_number
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}




## create and display ssh keys
resource "tls_private_key" "k8sKey" {
  algorithm                 = "RSA"
  rsa_bits                  = 4096
  
}




# Create the two Linux VMs associating the vNIcs created earlier associating it with its own AS
resource "azurerm_linux_virtual_machine" "linuxVMs" {
	count                 = var.VM_number
	name                  = "terraform-${count.index}"
	location              = var.location
	resource_group_name   = azurerm_resource_group.terraform-RG.name
	size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
	availability_set_id   = azurerm_availability_set.test_AS.id
	computer_name  		    ="k8s-${count.index}"
  admin_username 		    = "azureuser"
	disable_password_authentication = true
  
    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
	os_disk {
			name              = "myOsDisk"
			caching           = "ReadWrite"
			storage_account_type = "Standard_LRS"
		}
		
    admin_ssh_key {
        username       = "azureuser"
        public_key     = file("~/.ssh/id_rsa.pub")
    }
	
	depends_on = [
    azurerm_network_interface.main
  ]

}


output "VMIps" {
  value       = azurerm_public_ip.vmIps.*.ip_address
}


output "SSH" {
  value       = tls_private_key.k8sKey.private_key_pem
  sensitive = true
}
