# -----------------------------------------------------------------------------
# Azure Managed Redis — Balanced tier
# azurerm provider support is via azurerm_redis_enterprise_* resources for the
# legacy Enterprise SKUs; Azure Managed Redis (Balanced/MemoryOptimized/etc.)
# is provisioned via the Microsoft.Cache/redisEnterprise API using azapi.
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

resource "azapi_resource" "redis" {
  type      = "Microsoft.Cache/redisEnterprise@2024-09-01-preview"
  name      = var.redis_name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = var.tags

  body = {
    sku = {
      name = var.redis_sku_size # B0 dev/staging; prod size decided from dev metrics
    }
    properties = {
      minimumTlsVersion = "1.2"
      highAvailability  = "Enabled" # standard: zone-redundant replica pair
    }
  }

  response_export_values = ["properties.hostName"]
}

# Database within the Redis instance (where access policies + port live)
resource "azapi_resource" "redis_db" {
  type      = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
  name      = "default"
  parent_id = azapi_resource.redis.id

  body = {
    properties = {
      clientProtocol   = "Encrypted"  # TLS required
      port             = 10000        # Azure Managed Redis port (NOT 6380)
      evictionPolicy   = "NoEviction" # sessions must not be silently evicted; memory alerts give early warning
      clusteringPolicy = "OSSCluster"
      persistence = {
        aofEnabled = false
        rdbEnabled = false
      }
      accessKeysAuthentication = "Disabled" # Entra ID only — no access keys
    }
  }
}

# -----------------------------------------------------------------------------
# Access Policy Assignment — the "guest list" entry
# Grants the UAMI data-plane access to Redis. This is NOT Azure RBAC/IAM.
# -----------------------------------------------------------------------------
resource "azapi_resource" "redis_access_policy" {
  type = "Microsoft.Cache/redisEnterprise/databases/accessPolicyAssignments@2024-09-01-preview"
  name      = "appsvcUamiContributor"
  parent_id = azapi_resource.redis_db.id

  body = {
    properties = {
      accessPolicyName = "default" # built-in policy; full data access
      user = {
        objectId = var.uami_principal_id
      }
    }
  }
}
