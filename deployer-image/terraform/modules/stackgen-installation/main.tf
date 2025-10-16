
locals {
  temporal_helm_version             = "0.57.0"
  postgresql_administrator_password = random_password.db_password.result
  postgresql_fqdn                   = "postgres-postgresql.${helm_release.postgresql.namespace}.svc.cluster.local"
  postgresql_administrator_login    = "stackgen"
  release_name                      = "appcd"
  appcd_service_account             = "stackgen-ns-${var.suffix}"
}


resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "stackgen_identity" {
  metadata {
    name      = local.appcd_service_account
    namespace = var.namespace
  }
}



resource "kubernetes_config_map" "dex_configmap" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "dex-configmap"
    namespace = var.namespace
  }
  data = {
    stylecss : templatefile("./values/dex/style.css", {})
    header : templatefile("./values/dex/header.html", {})
    footer : templatefile("./values/dex/footer.html", {})
    login : templatefile("./values/dex/login.html", {})
    banner : templatefile("./values/dex/banner.html", {})
  }
}

resource "helm_release" "dex" {
  depends_on = [
    kubernetes_config_map.dex_configmap
  ]
  count            = var.stackgen_authentication.type == "none" ? 0 : 1
  name             = "dex"
  repository       = "https://charts.dexidp.io"
  chart            = "dex"
  namespace        = var.namespace
  create_namespace = false
  version          = "0.19.1"
  values = [
    templatefile("./values/dex.yaml", {
      host_domain               = var.domain,
      appcd_authentication_type = var.stackgen_authentication.type
      appcd_authentication_config = indent(8, yamlencode(merge({
        redirectURI : "https://${var.domain}/auth/callback"
      }, var.stackgen_authentication.config))),
      rds_endpoint = local.postgresql_fqdn
    })
  ]
}

resource "random_id" "appcd_client_id" {
  byte_length = 16
}

resource "random_id" "appcd_client_secret" {
  byte_length = 36
}

resource "kubernetes_secret" "ghcr_pkg" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "ghcr-pkg"
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" = {
        "https://ghcr.io" = {
          "username" = "github_username"
          "password" = var.STACKGEN_PAT
          "email"    = "support"
          "auth"     = base64encode("github_username:${var.STACKGEN_PAT}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_secret" "temporal_visibility_store" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "temporal-visibility-store"
    namespace = var.namespace
  }

  data = {
    password = local.postgresql_administrator_password
  }

  type = "Opaque"
}

resource "kubernetes_secret" "appcd_secrets" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "appcd-secrets"
    namespace = var.namespace
  }

  type = "Opaque"

  data = {
    rds_port            = "5432"
    rds_password        = local.postgresql_administrator_password
    rds_endpoint        = local.postgresql_fqdn
    rds_host            = local.postgresql_fqdn
    rds_read_endpoint   = local.postgresql_fqdn
    rds_username        = local.postgresql_administrator_login
    appcd_client_id     = random_id.appcd_client_id.hex
    appcd_client_secret = random_id.appcd_client_secret.hex
  }
}

locals {
  secret_data = {}

  github_secrets = var.scm_configuration.scm_type == "github" ? {
    scm_github_client_id     = var.scm_configuration.github_config.client_id
    scm_github_client_secret = var.scm_configuration.github_config.client_secret
  } : {}

  gitlab_secrets = var.scm_configuration.scm_type == "gitlab" ? {
    gitlab_client_id     = var.scm_configuration.gitlab_config.client_id
    gitlab_client_secret = var.scm_configuration.gitlab_config.client_secret
  } : {}

  azure_devops_secrets = var.scm_configuration.scm_type == "azuredev" ? {
    scm_azure_devops_client_id     = var.scm_configuration.azuredev_config.client_id
    scm_azure_devops_client_secret = var.scm_configuration.azuredev_config.client_secret
  } : {}

  final_scm_secrets = merge(
    local.secret_data,
    local.github_secrets,
    local.gitlab_secrets,
    local.azure_devops_secrets,
  )
}

# add secrets for auth and scm
resource "kubernetes_secret" "appcd_scm_secrets" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "appcd-scm-secrets"
    namespace = var.namespace
  }

  data = local.final_scm_secrets
}

resource "kubernetes_secret" "temporal_default_store" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "temporal-default-store"
    namespace = var.namespace
  }

  data = {
    password = local.postgresql_administrator_password
  }

  type = "Opaque"
}

resource "helm_release" "temporal" {
  depends_on = [kubernetes_secret.temporal_visibility_store, kubernetes_secret.temporal_default_store, helm_release.postgresql]
  name       = "temporal"
  chart      = "https://github.com/temporalio/helm-charts/releases/download/temporal-${local.temporal_helm_version}/temporal-${local.temporal_helm_version}.tgz"
  namespace  = var.namespace
  wait       = true
  values = [
    templatefile("./values/temporal.yaml", {
      enable_ops : var.enable_ops,
      domain : var.domain,
      postgres_host : local.postgresql_fqdn,
      postgres_port : 5432,
      postgres_user : local.postgresql_administrator_login
      namespace : var.namespace
    })
  ]
}

resource "kubernetes_persistent_volume_claim" "this" {
  depends_on = [kubernetes_namespace.this]
  metadata {
    name      = "storage-${var.namespace}"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard-rwo"
    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

locals {
  appcdYAML = templatefile("./values/appcd.yaml", {
    temporal_namespace : var.namespace
    appcd_secrets : concat([kubernetes_secret.appcd_secrets.metadata[0].name, kubernetes_secret.appcd_scm_secrets.metadata[0].name], var.additional_secrets)
    enable_ops : var.enable_ops
    domain : var.domain
    enable_ingress : true
    auth_enabled : var.stackgen_authentication.type != "none"
    scm_github_auth_url : try(var.scm_configuration.github_config.auth_url, "")
    scm_github_token_url : try(var.scm_configuration.github_config.token_url, "")
    scm_gitlab_auth_url : try(var.scm_configuration.gitlab_config.auth_url, "")
    scm_gitlab_token_url : try(var.scm_configuration.gitlab_config.token_url, "")
    scm_azure_auth_url : try(var.scm_configuration.azuredev_config.auth_url, "")
    scm_azure_token_url : try(var.scm_configuration.azuredev_config.token_url, "")
    enable_feature : var.enable_feature
    appcd_admin_emails : var.admin_emails
    enable_storage : length(var.storage.volume) > 0
    appcd_service_account : local.appcd_service_account
    nginx : var.nginx_config
    worm_enabled : false
  })
}

resource "helm_release" "stackgen" {
  depends_on = [
    kubernetes_service_account.stackgen_identity,
  ]
  name      = local.release_name
  chart     = "appcd-dist-${var.stackgen_version}.tgz"
  namespace = var.namespace
  wait      = true
  values = [
    local.appcdYAML,
    templatefile("./values/images.yaml", {})
  ]
}

resource "local_file" "appcd_yaml" {
  content  = local.appcdYAML
  filename = "./values/appcd-final.yaml"
}
