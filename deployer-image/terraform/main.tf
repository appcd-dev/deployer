locals {
  labels = merge(var.labels, {
    "maintainer" = "stackgen"
  })
}

provider "google" {
  project = var.project_id
  region  = var.region
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
  insecure               = false
}



module "stackgen" {
  source                            = "./modules/stackgen-installation"
  domain                            = var.domain
  STACKGEN_PAT                      = var.STACKGEN_PAT
  project_id                        = var.project_id
  suffix                            = var.suffix
}
