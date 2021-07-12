## Ensures 2.0+ of the azurevm provider to get the azurerm_windows_virtual_machine resource and
## the other resources and capabilities
provider "azurerm" {
  version = "2.0.0"
  subscription_id = "${ var.subscription_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  tenant_id = "${var.tenant_id}"
}

variable "subscription_id {
    #description = "Subscription ID of Azure user" 
}

variable "client_id" {
     #description = "App ID of Azure user"
}
variable "client_secret" {
    #description = "App password of Azure user"
}
variable "tenant_id" {
    #description = "Tenant ID of Azure user"
}
variable "location" {
    #description = "location of instance"
}

variable "network_security_group" {}
variable "virtual_network" {}

variable "VM_number" {}


