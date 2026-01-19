# 🔐 Sealed Secrets (kubeseal) – Secure GKE-Compatible Setup & Usage Guide

This guide explains how to install and use **Sealed Secrets** in a **hardened, production-safe configuration** that is compatible with:

- ✅ GKE Autopilot
- ✅ GKE Standard (restricted clusters)
- ✅ GitOps (ArgoCD / Flux)
- ✅ Multi-team, zero-trust environments

This setup **avoids cluster-wide privileges** and follows **least-privilege security principles**.

---

## 📌 What This Guide Covers

1. Installing the Sealed Secrets controller (secure Helm install)
2. Installing the `kubeseal` CLI
3. Fetching the public encryption key
4. Creating a Kubernetes Secret (dry run)
5. Encrypting the Secret using **namespace scope**
6. Deploying the SealedSecret
7. Verifying that decryption worked
8. Understanding **scope** and **security guarantees**

---

## 🔐 Why This Setup Is Safer (Important)

Unlike the default installation, this setup:

- ❌ Does **not** create ClusterRoles or ClusterRoleBindings
- ❌ Does **not** allow cluster-wide secret reuse
- ❌ Does **not** bind to `system:authenticated`
- ✅ Limits secrets to a **single namespace**
- ✅ Reduces blast radius if a secret file leaks
- ✅ Is compliant with GKE Autopilot security rules

> **Result:** Even if someone steals a sealed secret file, it cannot be decrypted outside its intended namespace.

---

## 📌 Prerequisites

- Kubernetes cluster access
- `kubectl` configured and working
- `helm` installed
- Namespace-level permissions are sufficient (cluster-admin NOT required)

Verify:
```bash
kubectl get nodes
helm version
```

---

## 1️⃣ Install Sealed Secrets Controller (Secure Helm Install)

### Add Helm repository

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
```

### Install controller (Hardened Configuration)

```bash
helm install sealed-secrets sealed-secrets/sealed-secrets \
  -n sealed-secrets --create-namespace \
  --set fullnameOverride=sealed-secrets-controller \
  --set-string webhooks.tlsSecretName=sealed-secrets-tls \
  --set rbac.create=true \
  --set rbac.createClusterRole=false \
  --set rbac.createClusterRoleBinding=false \
  --set rbac.serviceProxier.create=false \
  --set rbac.serviceProxier.bind=false \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=128Mi \
  --set resources.limits.cpu=100m \
  --set resources.limits.memory=128Mi \
  --wait
```

### Verify controller

```bash
kubectl get pods -n sealed-secrets | grep sealed
```

---

## 2️⃣ Install kubeseal CLI

```bash
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/kubeseal-0.34.0-linux-amd64.tar.gz"
tar -xvzf kubeseal-0.34.0-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

Verify:
```bash
kubeseal --version
```

---

## 3️⃣ Fetch the Public Encryption Key

```bash
kubeseal \
  --controller-name sealed-secrets-controller \
  --controller-namespace sealed-secrets \
  --fetch-cert > sealed-secrets-public.pem
```

---

## 4️⃣ Create a Kubernetes Secret (Dry Run)

```bash
kubectl create secret generic app-secret \
  --from-literal=API_KEY=killercoda-test \
  -n default \
  --dry-run=client -o yaml > secret.yaml
```

---

## 5️⃣ Encrypt the Secret (IMPORTANT: Scope Explained)

```bash
kubeseal \
  --cert sealed-secrets-public.pem \
  --scope namespace-wide \
  --format yaml \
  < secret.yaml > sealed-secret.yaml
```

---

## 6️⃣ Deploy the SealedSecret

```bash
kubectl apply -f sealed-secret.yaml
```

---

## 7️⃣ Verify That Decryption Worked

```bash
kubectl get secret app-secret -n default
kubectl get secret app-secret -n default -o jsonpath='{.data.API_KEY}' | base64 --decode && echo
```

---

## 8️⃣ Verify Using a Pod (Recommended)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test
  namespace: default
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh", "-c", "echo API_KEY=$API_KEY && sleep 3600"]
    envFrom:
    - secretRef:
        name: app-secret
```

---

## 🔐 Security Summary

- Secrets encrypted locally
- Private key stays in cluster
- Namespace-scoped decryption
- GitOps safe
- GKE Autopilot compliant
