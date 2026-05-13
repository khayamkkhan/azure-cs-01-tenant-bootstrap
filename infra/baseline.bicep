targetScope = 'subscription'

// =============================================================================
// Parameters
// =============================================================================

@description('Azure region for all baseline resources.')
param location string = 'eastus'

@description('Resource group name that holds all always-on baseline resources.')
param rgName string = 'rg-portfolio-baseline'

@description('Log Analytics workspace name. Becomes the central log destination for the portfolio.')
param workspaceName string = 'log-portfolio-baseline'

@description('Default tags applied to every resource. Matches the tag-policy expectation.')
param defaultTags object = {
  owner: 'khayam'
  environment: 'lab'
  project: 'baseline'
}

@description('Email recipient for budget alert notifications.')
param alertEmail string = 'khan.khayam.koh@gmail.com'

@description('Monthly budget cap in USD.')
@minValue(1)
@maxValue(100)
param monthlyBudget int = 10

@description('Workspace retention in days. 30 stays inside the Log Analytics free tier (5 GB/month).')
@minValue(30)
@maxValue(730)
param retentionDays int = 30

// =============================================================================
// 1. Resource Group
// =============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: defaultTags
}

// =============================================================================
// 2. Log Analytics Workspace (deployed via module into the RG)
// =============================================================================

module law 'modules/law.bicep' = {
  scope: rg
  name: 'deploy-law'
  params: {
    workspaceName: workspaceName
    location: location
    tags: defaultTags
    retentionDays: retentionDays
  }
}

// =============================================================================
// 3. Subscription-scope diagnostic setting → Log Analytics Workspace
// =============================================================================

resource activityLogToLAW 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-activity-log-to-law'
  properties: {
    workspaceId: law.outputs.workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'ServiceHealth', enabled: true }
      { category: 'Alert', enabled: true }
      { category: 'Recommendation', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Autoscale', enabled: true }
      { category: 'ResourceHealth', enabled: true }
    ]
  }
}

// =============================================================================
// 4. Tag policy assignments — built-in "Require a tag on resources" × 3
// =============================================================================

var requireTagPolicyId = tenantResourceId(
  'Microsoft.Authorization/policyDefinitions',
  '871b6d14-10aa-478d-b590-94f262ecfa99'
)

var requiredTags = [ 'owner', 'environment', 'project' ]

resource tagPolicies 'Microsoft.Authorization/policyAssignments@2024-04-01' = [for tag in requiredTags: {
  name: 'require-tag-${tag}'
  properties: {
    displayName: 'Require ${tag} tag on resources'
    description: 'Audits resources missing the ${tag} tag.'
    policyDefinitionId: requireTagPolicyId
    definitionVersion: '1.*.*'
    enforcementMode: 'Default'
    parameters: {
      tagName: { value: tag }
    }
  }
}]

// =============================================================================
// 5. Monthly budget — portfolio-monthly-cap
// =============================================================================

resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'portfolio-monthly-cap'
  properties: {
    timePeriod: {
      startDate: '2026-05-01T00:00:00Z'
      endDate: '2030-01-01T00:00:00Z'
    }
    timeGrain: 'Monthly'
    amount: monthlyBudget
    category: 'Cost'
    notifications: {
      actual_GreaterThan_50_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        contactEmails: [ alertEmail ]
        thresholdType: 'Actual'
      }
      actual_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: [ alertEmail ]
        thresholdType: 'Actual'
      }
    }
  }
}

// =============================================================================
// Outputs
// =============================================================================

output workspaceId string = law.outputs.workspaceId
output workspaceName string = law.outputs.workspaceName
output rgId string = rg.id
output rgName string = rg.name
