provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
 name     = "${var.prefix}"
 location = var.location
}

output "image_id" {
 value =  "/subscriptions/b7a92848-8383-4e6c-b706-1d481cbdc22f/resourceGroups/Udacity-cli-rg/providers/Microsoft.Compute/images/MyUbuntuImage" 
}

data "azurerm_image" "search" {
  name                = "MyUbuntuImage"
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_virtual_network" "test" {
 name                = "var.prefix-network"
 address_space       = ["10.0.0.0/24"]
 location            = azurerm_resource_group.test.location
 resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
 name                 = "test"
 resource_group_name  = azurerm_resource_group.test.name
 virtual_network_name = azurerm_virtual_network.test.name
 address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "test" {
  name                = "test-nsg"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = azurerm_subnet.test.id
  network_security_group_id = azurerm_network_security_group.test.id
}

resource "azurerm_public_ip" "test" {
 name                         = "publicIPForLB"
 location                     = azurerm_resource_group.test.location
 resource_group_name          = azurerm_resource_group.test.name
 allocation_method            = "Static"
}

resource "azurerm_lb" "test" {
 name                = "loadBalancer"
 location            = azurerm_resource_group.test.location
 resource_group_name = azurerm_resource_group.test.name

 frontend_ip_configuration {
   name                 = "publicIPAddress"
   public_ip_address_id = azurerm_public_ip.test.id
 }
}

resource "azurerm_lb_backend_address_pool" "test" {
 resource_group_name = azurerm_resource_group.test.name
 loadbalancer_id     = azurerm_lb.test.id
 name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "test" {
 count               = var.vm_count
 name                = "acctni${count.index}"
 location            = azurerm_resource_group.test.location
 resource_group_name = azurerm_resource_group.test.name

 ip_configuration {
   name                          = "testConfiguration"
   subnet_id                     = azurerm_subnet.test.id
   private_ip_address_allocation = "dynamic"
 }
}

resource "azurerm_managed_disk" "test" {
 count                = var.vm_count
 name                 = "datadisk_existing_${count.index}"
 location             = azurerm_resource_group.test.location
 resource_group_name  = azurerm_resource_group.test.name
 storage_account_type = "Standard_LRS"
 create_option        = "Empty"
 disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
 name                         = "var.setname"
 location                     = azurerm_resource_group.test.location
 resource_group_name          = azurerm_resource_group.test.name
 platform_fault_domain_count  = 2
 platform_update_domain_count = 2
 managed                      = true
}

resource "azurerm_virtual_machine" "test" {
 count                 = var.vm_count
 name                  = "acctvm${count.index}"
 location              = azurerm_resource_group.test.location
 availability_set_id   = azurerm_availability_set.avset.id
 resource_group_name   = azurerm_resource_group.test.name
 network_interface_ids = [element(azurerm_network_interface.test.*.id, count.index)]
 vm_size               = "Standard_DS2_v3"

 storage_image_reference {
 id = "data.azurerm_image.search.id"
  }

 storage_os_disk {
   name              = "myosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 # Optional data disks
 storage_data_disk {
   name              = "datadisk_new_${count.index}"
   managed_disk_type = "Standard_LRS"
   create_option     = "Empty"
   lun               = 0
   disk_size_gb      = "1023"
 }

 storage_data_disk {
   name            = element(azurerm_managed_disk.test.*.name, count.index)
   managed_disk_id = element(azurerm_managed_disk.test.*.id, count.index)
   create_option   = "Attach"
   lun             = 1
   disk_size_gb    = element(azurerm_managed_disk.test.*.disk_size_gb, count.index)
 }

 os_profile {
   computer_name  = "hostname"
   admin_username = "var.username"
   admin_password = "var.password"
 }

 os_profile_linux_config {
   disable_password_authentication = false
 }

 tags = {
   environment = "staging"
 }
}