
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
    name                       = "http"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
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
  name                = "${var.name_prefix}_jumpbox_public_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  tags = {
    owner = "${var.name_prefix}_tsb"
  }
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "${var.name_prefix}_jumpbox_nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.name_prefix}_jumpbox_ip"
    subnet_id                     = var.vnet_subnet
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

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                  = "${var.name_prefix}-jumpbox"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = "Standard_F2s_v2"
  network_interface_ids = [azurerm_network_interface.jumpbox_nic.id]
  admin_username        = var.jumpbox_username
  custom_data = base64encode(templatefile("${path.module}/jumpbox.userdata", {
    jumpbox_username        = var.jumpbox_username
    tsb_version             = var.tsb_version
    tsb_image_sync_username = var.tsb_image_sync_username
    tsb_image_sync_apikey   = var.tsb_image_sync_apikey
    docker_login            = "docker login -u ${var.registry_username} -p ${var.registry_password} ${var.registry}"
    registry                = var.registry
    registry_admin          = var.registry_username
    registry_password       = var.registry_password
    pubkey                  = tls_private_key.generated.public_key_openssh
  }))


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
    username   = var.jumpbox_username
    public_key = "${trimspace(tls_private_key.generated.public_key_openssh)} ${var.jumpbox_username}@tetrate.io"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [tls_private_key.generated]

  # Up to 15 tags as per Azure
  tags = {
    owner = "${var.name_prefix}_tsb"
  }

}

resource "local_file" "tsbadmin_pem" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${var.name_prefix}-azure-${var.jumpbox_username}.pem"
  depends_on      = [tls_private_key.generated]
  file_permission = "0600"
}

resource "local_file" "ssh_jumpbox" {
  content         = "ssh -i ${var.name_prefix}-azure-${var.jumpbox_username}.pem -l ${var.jumpbox_username} ${azurerm_public_ip.jumpbox_public_ip.ip_address}"
  filename        = "ssh-to-azure-jumpbox.sh"
  file_permission = "0755"
}
