resource "helm_release" "sealed_secrets" {
  name      = "sealed-secrets"
  namespace = kubernetes_namespace.sealed_secrets.metadata[0].name

  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"

  # 🔒 FIXED chart version (matches cluster)
  version = "2.18.0"

  values = [
    file("${path.module}/values-sealed-secrets.yaml")
  ]

  wait    = true
  timeout = 600

  force_update  = true
  recreate_pods = true

  depends_on = [
    kubernetes_namespace.sealed_secrets
  ]
}
