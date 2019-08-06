# Create complete Linux VM in Azure using Terraform

# Azure Key Vault data source to access local admin password
data "azurerm_key_vault_secret" "mySecret" {
  name      = "labuser"
  key_vault_id = "/subscriptions/GUID/resourceGroups/RGName/providers/Microsoft.KeyVault/vaults/VaultName"
}

# get my external IP address to enter into NSG rule
data "http" "myExtIp" {
    url = "http://ident.me/"
}

# Create resource group
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "SecurityWorkshop"
    location = "westeurope"

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}

# Create public IP address
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "westeurope"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create NSG
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "${data.http.myExtIp.body}" #reference to http data source
        destination_address_prefix = "*"
    }

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create NIC
resource "azurerm_network_interface" "myterraformnic" {
    name                = "myNIC"
    location            = "westeurope"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create diagnostic storage account
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}
resource "azurerm_storage_account" "mystorageaccount" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
    location            = "westeurope"
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}

# Create VM
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "westeurope"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "labuser"
        admin_password = "${data.azurerm_key_vault_secret.mySecret.value}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Security Workshop"
        deployment = "Terraform"
    }
}
