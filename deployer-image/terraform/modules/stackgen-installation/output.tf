output "namespace" {
  value = var.namespace
}

output "release_name" {
  value = local.release_name
}

output "stackgen_version" {
  value = var.stackgen_version
}

output "appcd_values_file" {
  value = local_file.appcd_yaml.filename
}

output "appcd_yaml" {
  value = local.appcdYAML
}
