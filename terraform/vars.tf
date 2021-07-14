## Ensures 2.0+ of the azurevm provider to get the azurerm_windows_virtual_machine resource and
## the other resources and capabilities
provider "azurerm" {
  subscription_id = "${ var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

variable "subscription_id" {
    type = string
    #description = "Subscription ID of Azure user" 
}

variable "client_id" {
    type = string
     #description = "App ID of Azure user"
}
variable "client_secret" {
    type = string
    #description = "App password of Azure user"
}
variable "tenant_id" {
    type = string
    #description = "Tenant ID of Azure user"
}
variable "location" {
    type = string
    #description = "location of instance"
}

variable "network_security_group" {
    type = string
}

variable "resource_group" {
    type = string
}
variable "virtual_network" {
    type = string
}

variable "VM_number" {
    type = number
}


