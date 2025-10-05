resource "azurerm_linux_virtual_machine" "my_vm" {
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  name                = "my-vm-oct-5"
  size                = "Standard_D2s_v3"

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [azurerm_network_interface.main_nic.id]

}

resource "azurerm_virtual_network" "main_vnet" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
}

resource "azurerm_subnet" "example" {
  depends_on           = [azurerm_virtual_network.main_vnet]
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.255.0/24"]
}

resource "azurerm_network_interface" "main_nic" {

  location            = azurerm_resource_group.main_rg.location
  name                = "main-nic"
  resource_group_name = azurerm_resource_group.main_rg.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.example.id
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "main-pip"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "name" {
  network_security_group_id = azurerm_network_security_group.nsg.id
  subnet_id                 = azurerm_subnet.example.id
}

output "vm_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  value = "ssh ${azurerm_linux_virtual_machine.my_vm.admin_username}@${azurerm_public_ip.pip.ip_address}"

  # ssh -i <private_key.pem> username@IP_ADDRESS
}
