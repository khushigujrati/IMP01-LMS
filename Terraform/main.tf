# Configure the AzureRM Provider
provider "azurerm" {
      features {}
}

# Create a resource group
resource "azurerm_resource_group" "imp01" {
  name     = var.rg_name
  location = var.location
}

terraform {
  backend "azurerm" {
    resource_group_name  = "RG01-IMP01"
    storage_account_name = "khushidec2023lmp"
    container_name       = "allstatefiles"
    key                  = "terraform.tfstate"
  }
} 

#Create a storage account for boot diagnostic
resource "azurerm_storage_account" "boot_diags" {
  name                     = var.boot_diag_sa_name
  resource_group_name      = azurerm_resource_group.imp01.name
  location                 = azurerm_resource_group.imp01.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Prod"
  }
}

# Create a virtual network
resource "azurerm_virtual_network" "imp01" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.imp01.location
  resource_group_name = azurerm_resource_group.imp01.name
}

# Create a subnet
resource "azurerm_subnet" "imp01" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.imp01.name
  virtual_network_name = azurerm_virtual_network.imp01.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create a network interface
resource "azurerm_network_interface" "imp01" {
  count               = var.vm_count
  name                = "${var.nic_name}-${count.index}"
  location            = azurerm_resource_group.imp01.location
  resource_group_name = azurerm_resource_group.imp01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.imp01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.imp01[count.index].id
  }
}

#Create public IPs
resource "azurerm_public_ip" "imp01" {
  count                   = var.vm_count
  name                    = "${var.public_ip_name}-${count.index}"
  location                = azurerm_resource_group.imp01.location
  resource_group_name     = azurerm_resource_group.imp01.name
  allocation_method       = "Static"
}

# Create three virtual machines
resource "azurerm_virtual_machine" "imp01" {
  count                 = var.vm_count
  name                  = "${var.vm_name}-${count.index}"
  location              = azurerm_resource_group.imp01.location
  resource_group_name   = azurerm_resource_group.imp01.name
  network_interface_ids = [azurerm_network_interface.imp01[count.index].id]
  vm_size               = var.vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.os_disk_name}-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.os_disk_type
  }
  os_profile {
    computer_name  = "${var.os_computer_name}-${count.index}"
    admin_username = var.username
    admin_password = var.password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.boot_diags.primary_blob_endpoint
  }
}
