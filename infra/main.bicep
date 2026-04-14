targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Used for resource naming; set by azd to AZURE_ENV_NAME.')
param environmentName string

@minLength(1)
@description('Azure region (e.g. swedencentral).')
param location string

@description('Optional override for the resource group name.')
param resourceGroupName string = ''

@description('PostgreSQL flexible server administrator login (avoid reserved names such as azure_superuser).')
param postgresAdminLogin string = 'marketplaceadmin'

@secure()
@description('PostgreSQL administrator password. Use letters and numbers only so the DATABASE_URL stays valid.')
param postgresAdminPassword string

@secure()
param railsMasterKey string

@secure()
param smtpUsername string

@secure()
param smtpPassword string

@description('Verified Action Mailer From address (Azure Communication Services Email). Optional.')
param mailerFrom string = ''

@description('Stripe publishable key (pk_...), optional.')
param stripePublishableKey string = ''

@secure()
param stripeSecretPrivateKey string = ''

@secure()
param stripeWebhookSecret string = ''

@description('Full container image for the web app; azd sets SERVICE_WEB_IMAGE_NAME after deploy.')
param webImageName string = ''

@description('Set by azd so reprovision does not reset the deployed image to the placeholder.')
param webAppExists bool = false

@description('ACR login server suffix (azurecr.io or sovereign cloud equivalent).')
param containerRegistryHostSuffix string = 'azurecr.io'

var tags = {
  'azd-env-name': environmentName
  Project: 'cuhk-marketplace'
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var rgName = !empty(resourceGroupName) ? resourceGroupName : 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

module core 'core.bicep' = {
  scope: rg
  name: 'core'
  params: {
    location: location
    tags: tags
    resourceToken: resourceToken
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    railsMasterKey: railsMasterKey
    smtpUsername: smtpUsername
    smtpPassword: smtpPassword
    mailerFrom: mailerFrom
    stripePublishableKey: stripePublishableKey
    stripeSecretPrivateKey: stripeSecretPrivateKey
    stripeWebhookSecret: stripeWebhookSecret
    webImageName: webImageName
    webAppExists: webAppExists
    containerRegistryHostSuffix: containerRegistryHostSuffix
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_NAME string = core.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = core.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_ENVIRONMENT_NAME string = core.outputs.AZURE_CONTAINER_ENVIRONMENT_NAME

output POSTGRES_SERVER_FQDN string = core.outputs.POSTGRES_SERVER_FQDN
output POSTGRES_DATABASE_NAME string = core.outputs.POSTGRES_DATABASE_NAME

output SERVICE_WEB_NAME string = core.outputs.SERVICE_WEB_NAME
output SERVICE_WEB_URI string = core.outputs.SERVICE_WEB_URI
output SERVICE_WEB_IDENTITY_ID string = core.outputs.SERVICE_WEB_IDENTITY_ID

output AZURE_STORAGE_ACCOUNT_NAME string = core.outputs.AZURE_STORAGE_ACCOUNT_NAME
output AZURE_STORAGE_CONTAINER_NAME string = core.outputs.AZURE_STORAGE_CONTAINER_NAME
