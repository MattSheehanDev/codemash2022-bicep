param namePrefix string
param tags object


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

@description('app service subnet')
output appSubnetId string = vnet.properties.subnets[0].id
@description('function app subnet')
output fnSubnetId string = vnet.properties.subnets[1].id

