# Azure Resource Manager - linked templates

This folder contains examples for linked ARM templates.

For a tutorial, see [Tutorial: create linked Azure Resource Manager templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-tutorial-create-linked-templates).

## Link or nest a template

To link to another template, add a **deployments** resource to your main template.

```json
"resources": [
  {
      "apiVersion": "2017-05-10",
      "name": "linkedTemplate",
      "type": "Microsoft.Resources/deployments",
      "properties": {
          "mode": "Incremental",
          <nested-template-or-external-template>
      }
  }
]
```

## Main Template

The main template in this folder contains a **parameters** section that contains values that are either defined here or passed to the main template by an external call (e.g. an Az CLI or PowerShell call) and from there passed to the linked template.

If the **parameters** section is filled with values that are passed to the main template it will only contain the parameters definition.

```json
"parameters": {
            "vaultName": {
                "type": "string"
            },
            "vaultResourceGroup": {
                "type": "string"
            },
            "secretName": {
                "type": "string"
            }
        }
```

If the parameter values are defined within the template the configuration is:

```json
"parameters": {
            "vaultName": {
                "type": "string",
                "defaultValue": "<default-value-of-parameter>"
            },
            "vaultResourceGroup": {
                "type": "string",
                "defaultValue": "<default-value-of-parameter>"
            },
            "secretName": {
                "type": "string",
                "defaultValue": "<default-value-of-parameter>"
            }
        }
```

Access to an Azure KeyVault is possible within the **resources** section. The parameters **VaultResourceGroup** and **vaultName** are either defined in the main **parameters** section or passed to the template by an external call.

```json
"parameters": {
    "adminPassword": {
        "reference": {
            "keyVault": {
                "id": "[resourceId(subscription().subscriptionId,  parameters('VaultResourceGroup'), 'Microsoft.KeyVault/vaults', parameters('vaultName'))]"
            },
            "secretName": "[parameters('secretName')]"
        }
    }
}
```

## Linked Template

In the [linked template](https://github.com/azureandbeyond/AzureSecurity/ARM/LinkedTemplates/01_azuredeploy-infra.json) the infrastructure is deployed. In the parameters section the *adminUsername* **labuser** is defined, the *adminPassword* is passed by the main template.

```json
"parameters": {
    "adminUsername": {
        "type": "string",
        "defaultValue": "labuser",
        "metadata": {
            "description": ""
        }
    },
    "adminPassword": {
        "type": "securestring"
    }
},
```