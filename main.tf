resource "azurerm_resource_group" "resource" {
  name     = "worshopdec23"
  location = "Central India"

}

resource "azurerm_virtual_network" "network" {
  name                = "Network"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name
  depends_on          = [azurerm_resource_group.resource]
}
resource "azurerm_subnet" "subnet" {
  name                 = "web"
  resource_group_name  = azurerm_resource_group.resource.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["192.168.2.0/24"]
  depends_on           = [azurerm_virtual_network.network]
}
resource "azurerm_public_ip" "web" {
  name                = "webip"
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location
  allocation_method   = "Static"
  depends_on          = [azurerm_virtual_network.network]
}
resource "azurerm_network_interface" "webnic" {
  name                = "webnic"
  location            = azurerm_resource_group.resource.location
  resource_group_name = azurerm_resource_group.resource.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
  depends_on = [azurerm_subnet.subnet, azurerm_public_ip.web]
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "workshopinstance"
  resource_group_name = azurerm_resource_group.resource.name
  location            = azurerm_resource_group.resource.location
  size                = "Standard_B1s"
  admin_username      = "lenova"
  network_interface_ids = [
    azurerm_network_interface.webnic.id,
  ]

  admin_ssh_key {
    username   = "lenova"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  connection {
    type        = "ssh"
    user        = "lenova"
    private_key = file("~/.ssh/id_rsa")
    host        = azurerm_linux_virtual_machine.main.public_ip_address
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install java -y",
      "sudo apt install nginx -y",
      "wget https://referenceapplicationskhaja.s3.us-west-2.amazonaws.com/spring-petclinic-3.1.0-SNAPSHOT.jar"
    ]

  }
  depends_on = [azurerm_network_interface.webnic]
}
