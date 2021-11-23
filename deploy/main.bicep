@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

var appServiceAppName = 'kp-app-${resourceNameSuffix}'
var appServicePlanName = 'kp-app-plan'
var StorageAccountName = 'storage${resourceNameSuffix}'

// Define the SKUs for each component based on the environment type.
var environmentConfigurationMap = {
  nonprod: {
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    StorageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  prod: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    StorageAccount: {
      sku: {
        name: 'Standard_ZRS'
      }
    }
  }
}
var StorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${StorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${StorageAccount.listKeys().keys[0].value}'

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
}

resource appServiceAppAction 'Microsoft.Web/sites@2020-06-01' = {
  name: '${appServiceAppName}-pipeline'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'StorageAccountConnectionString'
          value: StorageAccountConnectionString
        }
      ]
    }
  }
}

resource appServiceAppPipeline 'Microsoft.Web/sites@2020-06-01' = {
  name: '${appServiceAppName}-action'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'StorageAccountConnectionString'
          value: StorageAccountConnectionString
        }
      ]
    }
  }
}

resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].StorageAccount.sku
}
