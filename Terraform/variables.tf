#"Resource Group" variables
variable "rg_name" {}
variable "location" {}

variable boot_diag_sa_name{}
variable "vnet_name" {}
variable "subnet_name" {}
variable "public_ip_name" {}
variable "nic_name" {}

#VM variables
variable "vm_count" {} 
variable "vm_name" {}
variable "vm_size" {}
variable "os_disk_name" {}
variable "os_disk_type" {}
variable "os_computer_name" {}

#Cred variables
variable "username" {}
variable "password" {}
