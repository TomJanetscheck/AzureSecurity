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