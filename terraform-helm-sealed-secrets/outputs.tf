output "namespace" {
  value = kubernetes_namespace.sealed_secrets.metadata[0].name
}

output "helm_release_name" {
  value = helm_release.sealed_secrets.name
}

output "chart_version" {
  value = helm_release.sealed_secrets.version
}
