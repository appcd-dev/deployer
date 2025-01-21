output "upgrade_command" {
  value = "helm upgrade --install appcd appcd-dist-${module.stackgen.stackgen_version}.tgz --namespace ${module.stackgen.namespace} --values ${module.stackgen.appcd_values_file} --values ${path.module}/values/images.yaml"
}
