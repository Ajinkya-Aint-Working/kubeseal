#!/usr/bin/env bash

set -e

PROJECT_DIR="terraform-helm-sealed-secrets"

echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ---------------------------
# versions.tf
# ---------------------------
echo "📝 Creating versions.tf"
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.4.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}
EOF

# ---------------------------
# providers.tf
# ---------------------------
echo "📝 Creating providers.tf"
cat > providers.tf << 'EOF'
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
EOF

# ---------------------------
# namespace.tf
# ---------------------------
echo "📝 Creating namespace.tf"
cat > namespace.tf << 'EOF'
resource "kubernetes_namespace" "sealed_secrets" {
  metadata {
    name = "sealed-secrets"
  }
}
EOF

# ---------------------------
# values-sealed-secrets.yaml
# ---------------------------
echo "📝 Creating values-sealed-secrets.yaml"
cat > values-sealed-secrets.yaml << 'EOF'
# -------------------------------------------------------------------
# sealed-secrets values
# Chart version pinned at install time: 2.18.0
# -------------------------------------------------------------------

fullnameOverride: sealed-secrets-controller

webhooks:
  tlsSecretName: sealed-secrets-tls

rbac:
  create: true
  createClusterRole: false
  createClusterRoleBinding: false

  serviceProxier:
    create: false
    bind: false

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 100m
    memory: 128Mi
EOF

# ---------------------------
# sealed-secrets-helm.tf
# ---------------------------
echo "📝 Creating sealed-secrets-helm.tf"
cat > sealed-secrets-helm.tf << 'EOF'
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
EOF

# ---------------------------
# outputs.tf
# ---------------------------
echo "📝 Creating outputs.tf"
cat > outputs.tf << 'EOF'
output "namespace" {
  value = kubernetes_namespace.sealed_secrets.metadata[0].name
}

output "helm_release_name" {
  value = helm_release.sealed_secrets.name
}

output "chart_version" {
  value = helm_release.sealed_secrets.version
}
EOF

echo ""
echo "✅ Terraform Helm sealed-secrets project created successfully!"
echo ""
echo "Next steps:"
echo "  cd terraform-helm-sealed-secrets"
echo "  terraform init"
echo "  terraform apply"
