terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

locals {
  labels = merge(var.labels, {
    "maintainer" = "stackgen"
  })
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}



module "stackgen" {
  source                = "./modules/stackgen-installation"
  domain                = var.domain
  STACKGEN_PAT          = var.STACKGEN_PAT
  suffix                = var.suffix
  global_static_ip_name = var.global_static_ip_name
  pre_shared_cert_name  = var.pre_shared_cert_name
  nginx_config          = var.nginx_config
  enable_feature        = var.enable_feature
}
