
resource "azurerm_network_security_group" "jumpbox_sg" {
  name                = "jumpbox_sg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "ssh"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "intravnet"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.cidr
    destination_address_prefix = var.cidr
  }
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}



resource "azurerm_public_ip" "jumpbox_public_ip" {
  name                         =  "${var.name_prefix}_jumpbox_public_ip"
  location                     = var.location
  resource_group_name          = var.resource_group_name
  allocation_method           = "Dynamic"
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                         =  "${var.name_prefix}_jumpbox_nic"
  location                     = var.location
  resource_group_name          = var.resource_group_name

  ip_configuration {
    name                          =  "${var.name_prefix}_jumpbox_ip"
    subnet_id                     =  var.vnet_subnets[0]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_public_ip.id
  }
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}

resource "azurerm_network_interface_security_group_association" "jumpbox_sga" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_sg.id
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "template_file" "jumpbox_userdata" {
  template = file("${path.module}/jumpbox.userdata")

  vars = {
    jumpbox_username    = var.jumpbox_username
    tsb_version         = var.tsb_version
    image-sync_username = var.image-sync_username
    image-sync_apikey   = var.image-sync_apikey
    registry            = var.registry
    registry_admin      = var.registry_username
    registry_password   = var.registry_password
    pubkey              = tls_private_key.generated.public_key_openssh
  }
}


resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                      = "${var.name_prefix}-jumpbox"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  size                      = "Standard_F2s_v2"
  network_interface_ids     = [ azurerm_network_interface.jumpbox_nic.id ]
  admin_username            = var.jumpbox_username
  custom_data               = base64encode(data.template_file.jumpbox_userdata.rendered)


  # az vm image list --output table

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "tsbadmin"
    public_key = "${trimspace(tls_private_key.generated.public_key_openssh)} tsbadmin@tetrate.io"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on        = [tls_private_key.generated]

  # Up to 15 tags as per Azure
  tags = {
    owner = "${var.name_prefix}_tsb"
  }

}

resource "local_file" "tsbadmin_pem" {
    content           = tls_private_key.generated.private_key_pem
    filename          = "${var.name_prefix}-tsbadmin.pem"
    depends_on        = [ tls_private_key.generated ]
}