targetScope = 'resourceGroup'

param fnAppName string


resource fnAi 'Microsoft.Insights/components@2020-02-02' = {
  name: '${fnAppName}-ai'
  location: resourceGroup().location
  kind: 'web'
}

resource fnAsp 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: '${fnAppName}-asp'
  location: resourceGroup().location
  sku: {
    // S1 is the minimum tier that supports VNet integration
    name: 'S1'
  }
}

resource fnApp 'Microsoft.Web/sites@2021-02-01' = {
  name: '${fnAppName}-fn'
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: fnAsp.id
    siteConfig: {
      
    }
  }
}
