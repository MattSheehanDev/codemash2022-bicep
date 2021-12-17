// This is the default scope.
// meaning modules will be deployed to the resource group level if omitted.
targetScope = 'resourceGroup'

// The @allowed annotation specifies what values can be used as arguments.
// Arguments not allowed will emit a validation error.
@allowed([
  'dev'
  'test'
  'prod'
])
param env string

@description('Must be at least S1 tier to support VNet integration')
param appSku string = 'S1'

// Secure parameters cannot have default values
@secure()
param sqlPassword string

// Object variable
var ownerTag = {
  Owner: 'DevTeam1'
}

var envTag = {
  dev: {
    Environment: 'Development'
  }
  test: {
    Environment: 'Testing'
  }
  prod: {
    Environment: 'Production'
  }
}

// Union will return an object with properties from both objects.
// Ex. output:
// {
//   Owner: 'DevTeam1'
//   Environment: 'Development'
// }
var tags = union(ownerTag, envTag[env])


// Virtual Networks are the backbone of all Azure resources.
// It is recommended that all subnets are deployed with the VNet at once and not as separate child resources.
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${env}-cm-vnet'
  // The resourceGroup function returns an object referencing the resource group
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      // Subnet for the App Service.
      // App Services require a delegated subnet.
      {
        name: '${env}-app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          // Service Endpoints secure connections to any of the listed services
          // by optimizing traffic to remain in the VNet.
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                resourceGroup().location
              ]
            }
            {
              service: 'Microsoft.Sql'
              locations: [
                resourceGroup().location
              ]
            }
            {
              service: 'Microsoft.Storage'
              locations: [
                resourceGroup().location
              ]
            }
          ]
          // Delegation just means that the App Service Plan has permission
          // to create service specific resources in the subnet.
          delegations: [
            {
              name: 'Microsoft.web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

// This a reference to the subnet created above.
// Because it references the vnet as it's parent, it is guaranteed to exist before referencing.
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  parent: vnet
  name: '${env}-app-subnet'
}


resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${env}-cm-asp'
  location: resourceGroup().location
  sku: {
    name: appSku
  }
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: '${env}-cm-app'
  location: resourceGroup().location
  identity: {
    // Enabling managed identities allow authentication without needed to store secrets or passwords
    type: 'SystemAssigned'
  }
  properties: {
    // Referencing the appServicePlan adds an implicit dependency,
    // the app service plan is guaranteed to be deployed before the app service.
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: appSubnet.id
  }
}


resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: '${env}-cm-sqlserver'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'codemash'
    administratorLoginPassword: sqlPassword
    // administrators: {
    //   administratorType: 'ActiveDirectory'
    //   principalType: 'Group'
    //   login: 'Database Admins'
    //   sid: 'ebc17081-586f-4228-a4f0-4cc58df98872'
    //   tenantId: tenant().tenantId
    //   azureADOnlyAuthentication: true
    // }
  }

  // This is a nested resource.
  // The full namespace of this resource is 'Microsoft.Sql/servers/databases@2021-05-01-preview'.
  // Nested resources inherit the parent namespace and api version.
  resource vnetRule 'virtualNetworkRules' = {
    name: '${env}-app-subnet-rule'
    properties: {
      virtualNetworkSubnetId: appSubnet.id
    }
  }
}

// This is a child resource explicity setting the parent property.
resource sqlDb 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  parent: sqlServer
  name: 'codemash-db'
  location: resourceGroup().location
  // Basic SKU with 5 DTUs
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}


resource stg 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${env}cmstg'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: appSubnet.id
        }
      ]
    }
  }
}

