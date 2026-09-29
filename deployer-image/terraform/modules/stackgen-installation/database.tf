##############################################################################
# Generate Random Password & Store in Secret
##############################################################################

resource "random_password" "db_password" {
  length  = 16
  special = true
}

##############################################################################
# Define PostgreSQL Values for Helm Chart
##############################################################################

locals {
  postgresql_values = {
    global = {
      postgresql = {
        auth = {
          username = "stackgen"
          password = random_password.db_password.result
          database = "stackgen"
        }
        maxConnections = 1000
      }
    }
    primary = {
      persistence = {
        enabled      = true
        size         = "50Gi"
        storageClass = "standard-rwo"
      }
      resources = {
        requests = {
          memory = "2Gi"
          cpu    = "500m"
        }
        limits = {
          memory = "4Gi"
          cpu    = "2000m"
        }
      }
      postgresql = {
        maxConnections = 500
        sharedBuffers  = "1GB"
      }
    }
    volumePermissions = {
      enabled = false
    }
    podSecurityContext = {
      enabled = true
      fsGroup = 1001
    }
    containerSecurityContext = {
      enabled = true
      runAsUser = 1001
      runAsNonRoot = true
    }
    tls = {
      enabled = false
    }
  }
}

##############################################################################
# Deploy Bitnami PostgreSQL Helm Chart
##############################################################################

resource "helm_release" "postgresql" {
  name = "postgres"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "18.0.15"

  namespace = var.namespace
  values = [
    yamlencode(local.postgresql_values) # Convert the object to a YAML string
  ]
}

##############################################################################
# Outputs for Validation
##############################################################################

output "postgresql_password" {
  value       = random_password.db_password.result
  description = "Randomly generated PostgreSQL password."
}

output "postgresql_namespace" {
  value       = helm_release.postgresql.namespace
  description = "Namespace where PostgreSQL is deployed."
}

output "postgresql_persistence_size" {
  value       = local.postgresql_values.primary.persistence.size
  description = "Persistence size allocated for PostgreSQL pri"
}
