
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name = "${var.prefix}-subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.vm_count
  name                = "${var.prefix}-${count.index + 1}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"  
}


resource "azurerm_network_interface" "vmnic" {
  
  count = var.vm_count
  name= "${var.prefix}-${count.index+1}-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm_public_ip[count.index].id
  }
}

resource "azurerm_network_security_group" "nsg" {

  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.vmnic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}



resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name = "${var.prefix}-${count.index+1}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  size  = "Standard_B1ls"


  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vmnic[count.index].id
  ]
  

  os_disk {
    name                 = "${var.prefix}-${count.index+1}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(<<EOF
#cloud-config
users:
  - name: ansible
    gecos: Ansible User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: $6$Yxxa9jrbCbT2WdhH$o4GzHHRhMmBJ2hItxlnbwBnRrxw5LZtOyfzwemVU9xZIjCflE.Ye5mVB2WJit.aNnYtM5yqSWcCw/.UPC42YS0
    ssh-authorized-keys:
      - ${file("id_ed25519.pub")}
EOF
  )

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

   tags = var.vm_tags[count.index]
}