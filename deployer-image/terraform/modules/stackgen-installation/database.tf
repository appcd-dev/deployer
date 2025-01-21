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
  postgresql_values = <<-EOT
    global:
      postgresql:
        auth:
          username: stackgen
          password: ${random_password.db_password.result}
          database: stackgen-db
    primary:
      persistence:
        enabled: true
        size: 20Gi
        storageClass: standard
    volumePermissions:
      enabled: true
      containerSecurityContext:
        runAsUser: 0
        runAsGroup: 0
    tls:
      enabled: false
  EOT
}

##############################################################################
# Deploy Bitnami PostgreSQL Helm Chart
##############################################################################

resource "helm_release" "postgresql" {
  name       = "my-postgresql"
  namespace  = "stackgen"
  chart      = "postgresql-16.4.3.tgz"

  values = [templatefile("./values/postgresql-values.yaml", {
    username = "stackgen"
    password = random_password.db_password.result
    database = "stackgen-db"
  })]
}
