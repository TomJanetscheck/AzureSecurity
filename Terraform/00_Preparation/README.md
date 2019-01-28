# Terraform - initial config

This project folder contains all code for your initial Terraform configuration.
The following configuration has been made and tested on macOS Mojave, Version 10.14.2.


## Content
This folder contains the following files:

| File | Description |
|------|-------------|
| README.md | this file |
| [00_createAzureADSP.sh](./00_createAzureADSP.sh) | Azure CLI script to create Azure AD service principal |
| [01_createBackendStorageKeyVault.sh](./01_createBackendStorageKeyVault.sh) | Azure CLI script to create backend storage and Azure KeyVault to store storage account key |
| [02_environmentVariables.sh](./02_environmentVariables.sh) | Bash script to export environment variables |


## Install Terraform

You can install Terraform using brew:

```bash
brew install terraform
```


## Azure AD Preparation

For Terraform being able to authenticate against Azure you need an Azure AD service principal.

```bash
#!/bin/sh

# Create Azure AD service principal in subscription <yourSubscriptionID>
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<yourSubscriptionID>"
```


## Azure Infrastructure Preparation

We create an Azure Storage Account that is used as Terraform Remote Backend for storing the .tfstore file. The following az cli script creates a new Azure Resource Group, Storage Account and Storage Container and stores the Storage Account key as a secret in a new Azure KeyVault.

```bash
#!/bin/bash

# Change these variables according to your needs
    RESOURCE_GROUP_NAME=terraformstate
    STORAGE_ACCOUNT_NAME=tfstate$RANDOM
    CONTAINER_NAME=tfstate
    VAULT_NAME=yourKeyVault$RANDOM
    SECRET_NAME=yourSecret

# Create Resource Group, Storage Account and Container for Terraform backend (securely storing Terraform plan)

# Create resource group
    az group create --name $RESOURCE_GROUP_NAME --location westeurope

# Create storage account
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
    ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
    az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

    echo "storage_account_name: $STORAGE_ACCOUNT_NAME"
    echo "container_name: $CONTAINER_NAME"
    echo "access_key: $ACCOUNT_KEY"

# Create Azure KeyVault
    az keyvault create -g $RESOURCE_GROUP_NAME --name $VAULT_NAME 

# Set Azure KeyVault Secret value to storage account key
    az keyvault secret set --vault-name $VAULT_NAME --name $SECRET_NAME --value $ACCOUNT_KEY
```


## Export Environment Variables

You can add the following lines to your .bashrc or .bash_profile (depending on the operating system you use). The ARM_ACCESS_KEY variable is the storage account key you need to access the storage account you created before. The storage account key is exported into your bash environment everytime you start a shell session.

```bash
echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=yourSubscriptionID
export ARM_CLIENT_ID=yourServicePrincipalAppID
export ARM_CLIENT_SECRET=yourServicePrincipalPassword
export ARM_TENANT_ID=yourAzureADTenantID
export ARM_ACCESS_KEY=$(az keyvault secret show --name yourKeyVaultSecretName --vault-name yourKeyVaultName --query value -o tsv)
# Not needed for public, required for usgovernment, german, china
export ARM_ENVIRONMENT=public
```