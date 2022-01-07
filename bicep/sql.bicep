
// We can omit the targetScope here since
// the deployment scope will be a resource group.

param namePrefix string

// Secure parameters cannot have default values.
@secure()
param sqlPassword string

// Verify that the array length has at least 1 item.
@minLength(1)
// Long strings can be broken into multiple lines.
@description('''
A list of subnet rule objects with the properties:
{
  name: string
  subnetId: string
}
''')
param vnetRules array


resource sqlServer 'Microsoft.Sql/servers@2021-05-01-preview' = {
  name: '${namePrefix}-cm-sqlserver'
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'codemash'
    administratorLoginPassword: sqlPassword
  }

  // This is a nested resource.
  // The full namespace of this resource is 'Microsoft.Sql/servers/databases@2021-05-01-preview'.
  // Nested resources inherit the parent namespace and api version.
  resource sqlDb 'databases' = {
    name: 'codemash-db'
    location: resourceGroup().location
    // Basic SKU with 5 DTUs
    sku: {
      name: 'Basic'
      tier: 'Basic'
      capacity: 5
    }
  }
}


// Loop through each vnet rule argument.
// These child resources explicity set the parent property.
resource vnetRule 'Microsoft.Sql/servers/virtualNetworkRules@2021-05-01-preview' = [for rule in vnetRules: {
  parent: sqlServer
  name: rule.name
  properties: {
    virtualNetworkSubnetId: rule.subnetId
  }
}]

output sqlServerName string = sqlServer.name
