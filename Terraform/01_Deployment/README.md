# Terraform - demo deployment

This project folder contains a demo Terraform deployment.


## Content
This folder contains the following files:

| File | Description |
|------|-------------|
| README.md | this file |
| [createEnvironment.tf](./createEnvironment.tf) | Terraform configuration file for resource deployment|


## About
The deployment will create a new Linux VM in Azure including the following Azure resources:

* Resource Group
* Virtual Network
* Subnet
* Public IP address
* Network Security Group incl. a security rule that grants SSH access only for the caller's current external IP address 
* Network interface card (NIC) incl. IP configuration
* Storage account to store operating system diagnostic logs
* Virtual machine incl. local admin password from Azure KeyVault


## Data sources

With data sources in Terraform we can reference external objects that are needed during deployments. The passage 

```bash

# Azure Key Vault data source to access local admin password
data "azurerm_key_vault_secret" "mySecret" {
  name      = "labuser"
  vault_uri = "https://yourKeyVault.vault.azure.net/"
}

# get my external IP address to enter into NSG rule
data "http" "myExtIp" {
    url = "http://ident.me/"
}
```

creates references to an Azure KeyVault secret in the Azure KeyVault *yourKeyVault*. The second http data source gets your external IP address from the website *ident.me* so it can be referenced later when creating the NSG rule.


## Data source references

Data sources are referenced in the respectice resource paragraphs.

```bash
[...]
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "${data.http.myExtIp.body}" # reference to http data source
        destination_address_prefix = "*"
    }
[...]
```

and

```bash
[...]    
    os_profile {
        computer_name  = "myvm"
        admin_username = "labuser"
        admin_password = "${data.azurerm_key_vault_secret.mySecret.value}" # reference to KeyVault secret
    }
[...]
```
