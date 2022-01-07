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


module vnet 'vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    namePrefix: namePrefix
    tags: tags
  }
}


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
    virtualNetworkSubnetId: vnet.outputs.appSubnetId
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
        subnetId: vnet.outputs.appSubnetId
      }
    ]
  }
}


module func 'fnapp.bicep' = {
  name: '${namePrefix}FnAppDeploy'
  params: {
    fnAppName: '${namePrefix}fnapp'
    subnetId: vnet.outputs.fnSubnetId
  }
}
