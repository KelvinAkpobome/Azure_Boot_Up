## Create an Azure resource group using the value of resource_group and the location of the location variable
## defined in the terraform.tfvars file built by Ansible.
resource "azurerm_resource_group" "test_RG" {
  name     = var.resource_group
  location = var.location
}
## Create a simple vNet
resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.test_RG.location
  resource_group_name = azurerm_resource_group.test_RG.name
}

## Create a simple subnet for VMs inside of the vNet ensuring the VNet is created first (depends_on)
resource "azurerm_subnet" "internal" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.test_RG.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"

  depends_on = [
    azurerm_virtual_network.main
  ]
}
## Create an availability set called test_AS which the VM will go into using the same location and resource
## group
resource "azurerm_availability_set" "test_AS" {
  name                = "test_AS"
  location            = azurerm_resource_group.test_RG.location
  resource_group_name = azurerm_resource_group.test_RG.name
}


## Create an Azure NSG from already existing nsg passed from tfvars to protect the infrastructure called my_nsg.
resource "azurerm_network_security_group" "my_nsg" {
  name                = var.network_security_group
  location            = azurerm_resource_group.monolithRG.location
  resource_group_name = azurerm_resource_group.monolithRG.name
  
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
  name                    = "publicVmIp-${count.index}"
  location                = azurerm_resource_group.test_RG.location
  resource_group_name     = azurerm_resource_group.test_RG.name
  allocation_method       = "Dynamic"
}

## Create a vNic for each windows VM. Using the count property to create two vNIcs while using ${count.index}
## to refer to each VM which will be defined in an array
resource "azurerm_network_interface" "main" {
  count               = var.VM_number
  name                = "test_NIC-${count.index}"
  location            = azurerm_resource_group.test_RG.location
  resource_group_name = azurerm_resource_group.test_RG.name
  
  ## Simple ip configuration for each vNic
  ip_configuration {
    name                          = "ip_config"
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
	name                  = "k8sVM-${count.index}"
	location              = var.location
	resource_group_name   = azurerm_resource_group.test_RG.name
	size                  = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.main[count.index].id]
	availability_set_id   = azurerm_availability_set.test_AS_linux.id
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
  value       = tls_private_key.SSH.private_key_pem
  sensitive = true
}
