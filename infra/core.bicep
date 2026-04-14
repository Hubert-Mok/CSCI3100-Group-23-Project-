@description('Primary location for resources in this resource group.')
param location string

param tags object

param resourceToken string

@description('PostgreSQL flexible server administrator login.')
param postgresAdminLogin string

@secure()
param postgresAdminPassword string

@secure()
param railsMasterKey string

@secure()
param smtpUsername string

@secure()
param smtpPassword string

@description('Verified Action Mailer From address (Azure Communication Services Email). Optional if set only in the portal.')
param mailerFrom string = ''

@description('Stripe publishable key (pk_...), optional.')
param stripePublishableKey string = ''

@secure()
param stripeSecretPrivateKey string = ''

@secure()
param stripeWebhookSecret string = ''

param webImageName string = ''

param webAppExists bool = false

param containerRegistryHostSuffix string = 'azurecr.io'

var webAppName = 'web-${resourceToken}'
var acrName = 'acr${resourceToken}'
var pgServerName = 'pg-${resourceToken}'
var logAnalyticsName = 'log-${resourceToken}'
var containerEnvName = 'cae-${resourceToken}'
var dbName = 'marketplace'
// Storage account names: 3–24 chars, lowercase letters and numbers only
var storageAccountName = 'st${resourceToken}'
var activeStorageContainerName = 'activestorage'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource containerAppsEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerEnvName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  #disable-next-line BCP334
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  #disable-next-line BCP334
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: activeStorageContainerName
  properties: {
    publicAccess: 'None'
  }
}

var storagePrimaryKey = storageAccount.listKeys().keys[0].value

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: pgServerName
  location: location
  tags: tags
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

resource pgFirewallAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgres
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource pgDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgres
  name: dbName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource webIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-web-${resourceToken}'
  location: location
  tags: tags
}

// AcrPull is created by the container-app-upsert -> acr-container-app registry-access module.
// Do not add a second role assignment here or deployment fails with RoleAssignmentExists.

var databaseUrl = 'postgresql://${postgresAdminLogin}:${postgresAdminPassword}@${postgres.properties.fullyQualifiedDomainName}:5432/${dbName}?sslmode=require'

var appMailHost = '${webAppName}.${containerAppsEnv.properties.defaultDomain}'

var appSecrets = concat(
  [
    {
      name: 'rails-master-key'
      value: railsMasterKey
    }
    {
      name: 'database-url'
      value: databaseUrl
    }
    {
      name: 'smtp-username'
      value: smtpUsername
    }
    {
      name: 'smtp-password'
      value: smtpPassword
    }
  ],
  !empty(stripeSecretPrivateKey)
    ? [
        {
          name: 'stripe-private'
          value: stripeSecretPrivateKey
        }
      ]
    : [],
  !empty(stripeWebhookSecret)
    ? [
        {
          name: 'stripe-webhook'
          value: stripeWebhookSecret
        }
      ]
    : [],
  [
    {
      name: 'azure-storage-access-key'
      value: storagePrimaryKey
    }
  ]
)

// Thruster must not bind :80 as non-root (USER 1000 in Dockerfile). HTTP_PORT=8080 matches ingress targetPort.
var appEnv = concat(
  [
    {
      name: 'HTTP_PORT'
      value: '8080'
    }
    {
      name: 'TARGET_PORT'
      value: '3000'
    }
    {
      name: 'RAILS_ENV'
      value: 'production'
    }
    {
      name: 'APP_HOST'
      value: appMailHost
    }
    {
      name: 'RAILS_MASTER_KEY'
      secretRef: 'rails-master-key'
    }
    {
      name: 'DATABASE_URL'
      secretRef: 'database-url'
    }
    {
      name: 'SMTP_USERNAME'
      secretRef: 'smtp-username'
    }
    {
      name: 'SMTP_PASSWORD'
      secretRef: 'smtp-password'
    }
  ],
  !empty(mailerFrom)
    ? [
        {
          name: 'MAILER_FROM'
          value: mailerFrom
        }
      ]
    : [],
  !empty(stripePublishableKey)
    ? [
        {
          name: 'STRIPE_SECRET_PUBLIC_KEY'
          value: stripePublishableKey
        }
      ]
    : [],
  !empty(stripeSecretPrivateKey)
    ? [
        {
          name: 'STRIPE_SECRET_PRIVATE_KEY'
          secretRef: 'stripe-private'
        }
      ]
    : [],
  !empty(stripeWebhookSecret)
    ? [
        {
          name: 'STRIPE_WEBHOOK_SECRET'
          secretRef: 'stripe-webhook'
        }
      ]
    : [],
  [
    {
      name: 'AZURE_STORAGE_ACCOUNT_NAME'
      value: storageAccount.name
    }
    {
      name: 'AZURE_STORAGE_ACCESS_KEY'
      secretRef: 'azure-storage-access-key'
    }
    {
      name: 'AZURE_STORAGE_CONTAINER'
      value: activeStorageContainerName
    }
  ]
)

module web 'br/public:avm/ptn/azd/container-app-upsert:0.3.0' = {
  name: 'marketplace-web'
  dependsOn: [
    pgFirewallAzure
    pgDatabase
    blobContainer
  ]
  params: {
    name: webAppName
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    containerAppsEnvironmentName: containerAppsEnv.name
    containerRegistryName: acr.name
    containerRegistryHostSuffix: containerRegistryHostSuffix
    imageName: webImageName
    exists: webAppExists
    identityType: 'UserAssigned'
    identityName: webIdentity.name
    userAssignedIdentityResourceId: webIdentity.id
    identityPrincipalId: webIdentity.properties.principalId
    targetPort: 8080
    ingressEnabled: true
    external: true
    containerMinReplicas: 1
    containerMaxReplicas: 5
    containerCpuCoreCount: '1.0'
    containerMemory: '2.0Gi'
    containerName: 'web'
    secrets: appSecrets
    env: appEnv
    enableTelemetry: false
  }
}

output AZURE_CONTAINER_REGISTRY_NAME string = acr.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.properties.loginServer
output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerAppsEnv.name

output POSTGRES_SERVER_FQDN string = postgres.properties.fullyQualifiedDomainName
output POSTGRES_DATABASE_NAME string = dbName

output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri
output SERVICE_WEB_IDENTITY_ID string = webIdentity.id

output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.name
output AZURE_STORAGE_CONTAINER_NAME string = activeStorageContainerName
