// Parameters
@description('Azure region where all resources will be deployed.')
param location string = 'East US'

@description('Globally unique name for the Azure Function App.')
param functionAppName string

@description('The runtime stack for the function app.')
@allowed([
  'dotnet'
  'node'
  'python'
  'java'
  'powershell'
])
param runtime string = 'node'

@description('Runtime version (e.g. Node.js 14).')
param runtimeVersion string = '14'

@description('Pricing SKU for the App Service plan.')
@allowed([
  'Y1'
  'B1'
  'P1v2'
  'S1'
])
param sku string = 'Y1'

// Variables
var storageAccountName = toLower('st${uniqueString(resourceGroup().id)}')
var planName = '${functionAppName}-plan'
var appInsightsName = '${functionAppName}-ai'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: planName
  location: location
  sku: {
    name: sku
    tier: (sku == 'Y1') ? 'Dynamic' : 'Standard'
  }
  properties: {
    reserved: false
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2015-05-01' = {
  name: appInsightsName
  location: location
  properties: {
    Application_Type: 'web'
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: runtime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: runtimeVersion
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
    }
    httpsOnly: true
  }
  dependsOn: [
    storageAccount
    appServicePlan
    appInsights
  ]
}

// Output
output functionAppHostname string = functionApp.properties.defaultHostName
