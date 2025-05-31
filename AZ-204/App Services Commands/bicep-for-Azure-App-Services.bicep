// Parameters
@description('Globally unique name for the Web App')
param webAppName string

@description('Location of the resources')
param location string = resourceGroup().location

@description('App Service Plan name')
param hostingPlanName string

@description('SKU name (e.g., F1, B1, S1, P1v3, I1v2)')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
  'I1'
  'I2'
  'I3'
  'I1v2'
  'I2v2'
  'I3v2'
])
param skuName string = 'P1v3'

@description('App Service pricing tier')
param skuTier string = 'PremiumV3'

@description('Instance count (number of workers)')
param workerSize int = 1

@description('Linux runtime stack (used only if isLinux = true)')
param linuxFxVersion string = 'NODE|18-lts'

@description('Set to true for Linux app, false for Windows')
param isLinux bool = true

@description('App settings (key-value pairs)')
param appSettings object = {
  ENVIRONMENT: 'Production'
  MySecret: 'SuperSecret123'
}

@description('Force HTTPS-only traffic')
param enableHttpsOnly bool = true

@description('Enable application diagnostics (logs, tracing, errors)')
param enableDiagnostics bool = true

@description('Enable staging deployment slot')
param enableStagingSlot bool = true

// App Service Plan
resource hostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: skuName
    tier: skuTier
    capacity: workerSize
  }
  properties: {
    reserved: isLinux  // true means Linux
  }
}

// Main Web App
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  dependsOn: [
    hostingPlan
  ]
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: enableHttpsOnly
    siteConfig: {
      linuxFxVersion: isLinux ? linuxFxVersion : null
      appSettings: [
        for key in appSettings: {
          name: key
          value: appSettings[key]
        }
      ]
    }
  }
}

// Diagnostics (optional)
resource webAppDiagnostics 'Microsoft.Web/sites/config@2022-03-01' = if (enableDiagnostics) {
  name: '${webApp.name}/web'
  properties: {
    detailedErrorLoggingEnabled: true
    httpLoggingEnabled: true
    requestTracingEnabled: true
  }
}

// Deployment slot (optional)
resource stagingSlot 'Microsoft.Web/sites/slots@2022-03-01' = if (enableStagingSlot) {
  name: '${webApp.name}/staging'
  location: location
  dependsOn: [
    webApp
  ]
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'ENVIRONMENT'
          value: 'Staging'
        }
        {
          name: 'MySecret'
          value: 'SlotSecret456'
        }
      ]
    }
  }
}
