

variable "subscription_id" {
    type = string
    #description = "Subscription ID of Azure user" 
}

variable "client_id" {
    type = string
     description = "App ID of Azure user"
}
variable "client_secret" {
    type = string
    description = "App password of Azure user"
}
variable "tenant_id" {
    type = string
    description = "Tenant ID of Azure user"
}
variable "location" {
    type = string
    description = "location of instance"
}


variable "VM_number" {
    type = number
}


