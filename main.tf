terraform {
  required_version = ">= 1.0.0" # Ensure that the Terraform version is 1.0.0 or higher

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.32.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  location = "France Central"
  name     = "AzureLabLVM"
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "lab-vnet"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "azure-lab-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}
resource "azurerm_public_ip" "public_ip" {
  allocation_method   = "Dynamic"
  location            = azurerm_resource_group.rg.location
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_interface" "network_interface" {
  location            = azurerm_resource_group.rg.location
  name                = "lab-net-interface"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm_lab" {
  name                = "vm-lab-azure-lvm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size             = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  admin_username = "azureuser"

  admin_ssh_key {
    public_key = file("~/.ssh/id_rsa.pub")
    username   = "azureuser"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 LTS
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

}
resource "azurerm_managed_disk" "dysk_1" {
  create_option        = "Empty"
  location             = azurerm_resource_group.rg.location
  name                 = "Disk_01"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  disk_size_gb = 10
}

resource "azurerm_managed_disk" "dysk_2" {
  create_option        = "Empty"
  location             = azurerm_resource_group.rg.location
  name                 = "Disk_02"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  disk_size_gb = 10
}

resource "azurerm_managed_disk" "dysk_3" {
  create_option        = "Empty"
  location             = azurerm_resource_group.rg.location
  name                 = "Disk_03"
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  disk_size_gb = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_1" {
  caching            = "ReadWrite"
  lun                = 0
  managed_disk_id    = azurerm_managed_disk.dysk_1.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm_lab.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_2" {
  caching            = "ReadWrite"
  lun                = 1
  managed_disk_id    = azurerm_managed_disk.dysk_2.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm_lab.id

}

resource "azurerm_virtual_machine_data_disk_attachment" "attach_3" {
  caching            = "ReadWrite"
  lun                = 2
  managed_disk_id    = azurerm_managed_disk.dysk_3.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm_lab.id
}


resource "null_resource" "run_lvm_setup" {
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.attach_3,
    azurerm_virtual_machine_data_disk_attachment.attach_1,
    azurerm_virtual_machine_data_disk_attachment.attach_2,
    azurerm_linux_virtual_machine.vm_lab
  ]

  connection {
    type = "ssh"
    user= "azureuser"
    private_key = file("~/.ssh/id_rsa")
    host = azurerm_linux_virtual_machine.vm_lab.public_ip_address
  }

  provisioner "file" {
    source = "skrypt.sh"
    destination = "/tmp/skrypt.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/skrypt.sh", // nadatanie uprawnien do wykonania
      "sudo /tmp/skrypt.sh"
    ]
  }
}