locals {
  labels = merge(var.labels, {
    "maintainer" = "stackgen"
  })
}

provider "helm" {
  kubernetes {
    host                   = "https://kubernetes.default.svc"
    token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
    insecure               = false
  }
}


provider "kubernetes" {
  host                   = "https://kubernetes.default.svc"
  token                  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
  cluster_ca_certificate = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
  # If the cluster CA is signed by a recognized authority, you can set 'insecure = false'
  insecure = false
}

module "stackgen" {
  source                = "./modules/stackgen-installation"
  domain                = var.domain
  STACKGEN_PAT          = var.STACKGEN_PAT
  suffix                = var.suffix
  global_static_ip_name = var.global_static_ip_name
  pre_shared_cert_name  = var.pre_shared_cert_name
}
