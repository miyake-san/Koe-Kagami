targetScope = 'resourceGroup'

@description('Base name used to derive resource names.')
param namePrefix string = 'koekagami'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Container image for the backend app.')
param backendImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Container image for the frontend app.')
param frontendImage string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Name of the Azure OpenAI model deployment.')
param openAiDeploymentName string = 'gpt-4o'

@description('Azure OpenAI model name.')
param openAiModelName string = 'gpt-4o'

@description('Azure OpenAI model version.')
param openAiModelVersion string = '2024-08-06'

var uniqueSuffix = uniqueString(resourceGroup().id)
var acrName = toLower('${namePrefix}acr${uniqueSuffix}')
var openAiName = '${namePrefix}-openai-${uniqueSuffix}'
var aiFoundryHubName = '${namePrefix}-hub-${uniqueSuffix}'
var aiFoundryProjectName = '${namePrefix}-project-${uniqueSuffix}'
var logAnalyticsName = '${namePrefix}-logs-${uniqueSuffix}'
var storageName = toLower('${namePrefix}st${uniqueSuffix}')
var keyVaultName = '${namePrefix}-kv-${uniqueSuffix}'
var environmentName = '${namePrefix}-env'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

resource openAiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: openAiDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAiModelName
      version: openAiModelVersion
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
  }
}

// Azure AI Foundry hub and project.
resource aiFoundryHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiFoundryHubName
  location: location
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: 'Koe-Kagami AI Foundry Hub'
    storageAccount: storage.id
    keyVault: keyVault.id
  }
}

resource aiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: aiFoundryProjectName
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: 'Koe-Kagami AI Foundry Project'
    hubResourceId: aiFoundryHub.id
  }
}

module containerApps 'modules/container-apps.bicep' = {
  name: 'container-apps'
  params: {
    location: location
    environmentName: environmentName
    namePrefix: namePrefix
    acrLoginServer: acr.properties.loginServer
    acrResourceId: acr.id
    logAnalyticsCustomerId: logAnalytics.properties.customerId
    logAnalyticsResourceId: logAnalytics.id
    backendImage: backendImage
    frontendImage: frontendImage
    openAiEndpoint: openAi.properties.endpoint
    openAiDeploymentName: openAiDeployment.name
  }
}

output acrLoginServer string = acr.properties.loginServer
output openAiEndpoint string = openAi.properties.endpoint
output aiFoundryHubId string = aiFoundryHub.id
output aiFoundryProjectId string = aiFoundryProject.id
output backendUrl string = containerApps.outputs.backendUrl
output frontendUrl string = containerApps.outputs.frontendUrl
