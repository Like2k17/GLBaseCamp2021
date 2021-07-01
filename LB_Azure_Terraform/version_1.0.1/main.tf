provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "main-rg"
  location = "eastus"
}

resource "azurerm_network_security_group" "main-nsg" {
  name                = "main-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "main-subnet" {
  name                 = "main-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_virtual_network" "main-vnet" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_public_ip" "main0-pip" {
  name                = "main0-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "standard"
  zones               = ["1"]
}

resource "azurerm_public_ip" "main1-pip" {
  name                = "main1-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "standard"
  zones               = ["2"]
}

resource "azurerm_network_interface" "main0-nic" {
  name                = "main0-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig0"
    subnet_id                     = azurerm_subnet.main-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main0-pip.id
  }
}

resource "azurerm_network_interface" "main1-nic" {
  name                = "main1-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.main-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main1-pip.id
  }
}

#*********************_____VM1_______******************************************

resource "azurerm_virtual_machine" "main-vm0" {
  name                  = "main-vm0"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main0-nic.id]
  vm_size               = "Standard_DS1_v2"
  zones                 = ["1"]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "disk0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "mainadmin"
    admin_password = var.azureuser_password
    custom_data    = file("script.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    Owner = "Bohdan"
  }
}
/*
resource "azurerm_lb_backend_address_pool_address" "main-vm0" {
  name                    = "main-vm0"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main-vms.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = "13.82.3.82"
}
*/
#*****************_____VM2_______*********************************************

resource "azurerm_virtual_machine" "main-vm1" {
  name                  = "main-vm1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main1-nic.id]
  vm_size               = "Standard_DS1_v2"
  zones                 = ["2"]

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "mainadmin"
    admin_password = var.azureuser_password
    custom_data    = file("script2.sh")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    Owner = "Bohdan"
  }
}

resource "azurerm_lb_backend_address_pool_address" "main-vm1" {
  name                    = "main-vm1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main-vms.id
  virtual_network_id      = azurerm_virtual_network.main-vnet.id
  ip_address              = "40.76.49.76"
}

#*********************_____LB_______******************************************

resource "azurerm_public_ip" "lb-pip" {
  name                = "lb-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "main-lb" {
  name                = "main-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-pip"
    public_ip_address_id = azurerm_public_ip.lb-pip.id
  }
}

resource "azurerm_lb_probe" "main-lbp" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main-lb.id
  name                = "http"
  port                = 80
}

resource "azurerm_lb_backend_address_pool" "main-vms" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main-lb.id
  name                = "main-http"
}

resource "azurerm_lb_rule" "main-lbr" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main-lb.id
  name                           = "Http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "lb-pip"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main-vms.id
  probe_id                       = azurerm_lb_probe.main-lbp.id
}
