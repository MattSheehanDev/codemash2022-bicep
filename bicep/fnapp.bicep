
param fnAppName string
param subnetId string


resource fnAi 'Microsoft.Insights/components@2020-02-02' = {
  name: '${fnAppName}-ai'
  location: resourceGroup().location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource fnStg 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${fnAppName}stg'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
    }
  }
}


resource fnAsp 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${fnAppName}-asp'
  location: resourceGroup().location
  sku: {
    name: 'S1'
  }
}

resource fnApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${fnAppName}-fn'
  location: resourceGroup().location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: fnAsp.id
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: fnAi.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: fnAi.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSIONS_VERSION'
          value: '~3'
        }
        // {
        //   name: 'AzureWebJobsStorage'
        //   value: stgConnectionStr
        // }
        {
          name: 'AzureWebJobsStorage_accountName'
          value: fnStg.name
        }
      ]
    }
  }
}


@description('''
This is the builtin Storage Blob Data Owner Role definition.
For a complete list of builtin role definitions see
https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
''')
resource blobDataOwnerRoleDef 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
}

// Role assignments are whats known as "extension resources"
// because they apply to another resource.
resource rbac 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: fnStg
  // Role assignment names must be globally unique.
  // Best practice is to generate a deterministic guid based off of
  // the scope id, principal id, and role id.
  name: guid(fnStg.id, fnApp.id, blobDataOwnerRoleDef.id)
  properties: {
    principalId: fnApp.identity.principalId
    roleDefinitionId: blobDataOwnerRoleDef.id
  }
}
