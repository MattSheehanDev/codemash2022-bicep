
resource stgacct1 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: 'storageaccount1'
  location: 'eastus'
  sku:{
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}
