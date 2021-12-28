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
param namePrefix string

@description('Must be at least S1 tier to support VNet integration')
param appSku string = 'S1'


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
var tags = union(ownerTag, envTag[namePrefix])


// Virtual Networks are the backbone of all Azure resources.
// It is recommended that all subnets are deployed with the VNet at once
// and not as separate child resources.
resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  // Prefix the resource names with the environment name
  // using string interpolation.
  name: '${namePrefix}-cm-vnet'
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
        name: '${namePrefix}-app-subnet'
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
      // Subnet for Function App.
      // Function Apps require a delegated subnet.
      {
        name: '${namePrefix}-fn-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
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


var appSubnet = vnet.properties.subnets[0]
var fnSubnet = vnet.properties.subnets[1]


resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${namePrefix}-cm-asp'
  location: resourceGroup().location
  sku: {
    name: appSku
  }
}

resource appService 'Microsoft.Web/sites@2021-02-01' = {
  name: '${namePrefix}-cm-app'
  location: resourceGroup().location
  identity: {
    // Enabling managed identities allow authentication
    // without needing to store secrets or passwords
    type: 'SystemAssigned'
  }
  properties: {
    // Referencing the appServicePlan adds an implicit dependency,
    // the app service plan is guaranteed to be deployed before the app service.
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: appSubnet.id
  }
}


// This a reference to that has already been created
// in a different resource group.
resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: 'kv-bicep-deployment'
  scope: resourceGroup('kv-bicep-rg')
}

module sql 'sql.bicep' = {
  name: '${namePrefix}SqlDeploy'
  params: {
    namePrefix: namePrefix
    sqlPassword: kv.getSecret('sql-password')
    vnetRules: [
      {
        name: '${namePrefix}-app-subnet-rule'
        subnetId: appSubnet.id
      }
    ]
  }
}


module func 'fnapp.bicep' = {
  name: '${namePrefix}FnAppDeploy'
  params: {
    fnAppName: '${namePrefix}fnapp'
    subnetId: fnSubnet.id
  }
}
