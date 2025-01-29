# Kubernetes Deployment
resource "kubernetes_config_map" "proxy_config" {
  metadata {
    name      = "proxy-config"
    namespace = var.namespace
  }

  data = {
    "nginx.conf" = join("\n", compact([
      templatefile("./values/proxy-base.conf.tpl", {
        domain    = var.domain,
        namespace = var.namespace
      }),
      var.stackgen_authentication.type != "none" ? file("${path.module}/dex-config.conf") : null
    ]))
  }
}

resource "kubernetes_deployment" "nginx_server" {
  depends_on = [helm_release.stackgen]
  metadata {
    name      = "proxy"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "proxy"
        }
      }

      spec {
        container {
          name  = "proxy"
          image = "nginx:1.21-alpine"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "proxy-config"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "nginx.conf"
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 80
            }
            initial_delay_seconds = 10
            period_seconds        = 15
          }
        }

        volume {
          name = "proxy-config"

          config_map {
            name = kubernetes_config_map.proxy_config.metadata[0].name
          }
        }
      }
    }
  }
}


# Kubernetes Service
resource "kubernetes_service" "nginx_service" {
  depends_on = [kubernetes_deployment.nginx_server]
  metadata {
    name      = "proxy"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "proxy"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# Kubernetes Ingress
resource "kubernetes_ingress_v1" "nginx_server_ingress" {
  metadata {
    name      = "proxy-ingress"
    namespace = var.namespace

    annotations = {
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = var.global_static_ip_name
      "ingress.gcp.kubernetes.io/pre-shared-cert"   = var.pre_shared_cert_name
    }
  }

  spec {
    rule {
      host = var.domain

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nginx_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
