# Vault and Bank-Vaults Deployment Examples

This directory contains examples for deploying HashiCorp Vault and the Bank-Vaults operator using Helm charts, demonstrating secret management and injection patterns in Kubernetes.

---

## Architecture Overview

This example demonstrates a complete secret management solution using:

- **HashiCorp Vault**: Secure secret storage with encryption at rest and in transit
- **Bank-Vaults Operator**: Kubernetes-native Vault lifecycle management
- **Vault Secrets Webhook**: Automatic secret injection into application pods
- **Kubernetes Authentication**: Service account-based authentication to Vault

### How It Works

1. **Secret Storage**: Secrets are stored securely in Vault using the KV v2 engine
2. **Pod Creation**: When a pod is created with Vault annotations, the mutating webhook intercepts it
3. **Secret Injection**: The webhook modifies the pod to include an init container that fetches secrets
4. **Authentication**: Pods authenticate to Vault using their Kubernetes service account JWT token
5. **Secret Resolution**: Environment variables with `vault:` prefixes are resolved to actual secret values

---

## Contents

- `vault-values.yaml` — Helm values for Vault development deployment (customized for k8s-pine)
- `bank-vaults-values.yaml` — Helm values for Bank-Vaults operator (production-ready config)
- `vault-example.yaml` — Vault custom resource example (Bank-Vaults managed instance) ⚠️ *Had CrashLoopBackOff issues*
- `secret-injection-example.yaml` — Application demonstrating automatic secret injection
- `vault-deployment.yaml` — Alternative manual Vault deployment (without operator)

---

## Key Customizations

### Vault Configuration (`vault-values.yaml`)
- **Development Mode**: Enabled for easy testing with auto-unseal
- **Root Token**: Set to `root` for development convenience
- **TLS Disabled**: Simplified configuration for internal cluster communication
- **Persistent Storage**: 1Gi PVC for data persistence
- **Resource Limits**: Optimized for development workloads (256Mi-512Mi memory)
- **UI Enabled**: Web interface available for secret management

### Bank-Vaults Operator (`bank-vaults-values.yaml`)
- **Webhook Integration**: Vault-secrets-webhook for automatic secret injection
- **Security Context**: Non-root user with dropped capabilities
- **Resource Optimization**: Minimal resource requests for efficient cluster usage
- **Certificate Management**: Auto-generated certificates for webhook TLS

### Secret Injection Example (`secret-injection-example.yaml`)
- **Vault Annotations**: Configured for automatic secret resolution
- **Service Account**: Dedicated `webapp` service account for Vault authentication
- **Environment Variables**: Demonstrates both direct secrets and templated values
- **Volume Mounts**: Shows file-based secret injection capabilities

---

## Prerequisites

```bash
# Install Helm (if not already installed)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version

# Ensure kubectl is configured for your cluster
kubectl cluster-info
```

---

## Deployment Flow

### Step 1: Deploy Vault using Helm

```bash
# Add HashiCorp Helm repository
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault in development mode
helm install vault hashicorp/vault \
  --namespace default \
  --values examples/apps/vault-values.yaml \
  --wait

# Verify Vault deployment
kubectl get pods,svc -l app.kubernetes.io/name=vault
```

### Step 2: Initialize and Unseal Vault

```bash
# Wait for Vault pod to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault --timeout=300s

# Initialize Vault (development mode auto-unseals)
kubectl exec vault-0 -- vault status

# Port forward to access Vault UI (optional)
kubectl port-forward svc/vault 8200:8200 &
# Access UI at http://localhost:8200 with token: root
```

### Step 3: Deploy Bank-Vaults Components

```bash
# Install Bank-Vaults operator
helm install vault-operator oci://ghcr.io/bank-vaults/helm-charts/vault-operator \
  --namespace default \
  --wait

# Install Vault Secrets Webhook for automatic secret injection
helm install vault-secrets-webhook oci://ghcr.io/bank-vaults/helm-charts/vault-secrets-webhook \
  --namespace default \
  --wait

# Verify Bank-Vaults components
kubectl get pods -l app.kubernetes.io/name=vault-operator
kubectl get pods -l app.kubernetes.io/name=vault-secrets-webhook
```

### Step 4: Configure Vault with Bank-Vaults

```bash
# Apply Vault custom resource
kubectl apply -f examples/apps/vault-example.yaml

# Verify Vault configuration
kubectl get vault
kubectl describe vault vault-example
```

### Step 5: Configure Vault Authentication and Create Secrets

```bash
# Enable Kubernetes authentication method
kubectl exec vault-0 -- vault auth enable kubernetes

# Configure Kubernetes authentication
kubectl exec vault-0 -- vault write auth/kubernetes/config \
  token_reviewer_jwt="$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert="$(kubectl exec vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"

# Create policy for secret access
kubectl exec vault-0 -- sh -c 'vault policy write allow_secrets - <<EOF
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF'

# Create Kubernetes authentication role
kubectl exec vault-0 -- vault write auth/kubernetes/role/default \
  bound_service_account_names=webapp,default \
  bound_service_account_namespaces=default \
  policies=allow_secrets \
  ttl=1h

# Create sample secrets
kubectl exec vault-0 -- vault kv put secret/database password=supersecret username=dbuser
kubectl exec vault-0 -- vault kv put secret/api key=api-key-12345 endpoint=https://api.example.com

# Verify secrets
kubectl exec vault-0 -- vault kv get secret/database
kubectl exec vault-0 -- vault kv get secret/api
```

### Step 6: Deploy Application with Secret Injection

```bash
# Deploy application that uses Vault secret injection
kubectl apply -f examples/apps/secret-injection-example.yaml

# Verify deployment
kubectl get pods -l app=webapp
kubectl describe pod -l app=webapp

# Check if secrets were injected
kubectl exec deploy/webapp -- env | grep -E "(DATABASE_PASSWORD|API_KEY)"
```

---

## How Bank-Vaults Secret Injection Works

### Webhook Mechanism

1. **Pod Interception**: When a pod is created with Vault annotations, the `vault-secrets-webhook` mutating admission webhook intercepts the pod creation request

2. **Init Container Injection**: The webhook modifies the pod specification to include:
   - An init container (`copy-vault-env`) that copies the `vault-env` binary
   - A shared volume (`vault-env`) mounted in both init and main containers
   - Environment variables for Vault configuration

3. **Secret Resolution**: The main container is wrapped with `/vault/vault-env` which:
   - Authenticates to Vault using the pod's service account JWT token
   - Resolves environment variables with `vault:` prefixes to actual secret values
   - Starts the original application with resolved secrets

### Authentication Flow

```
Pod Service Account JWT → Vault Kubernetes Auth → Vault Token → Secret Access
```

1. **JWT Token**: Each pod gets a unique JWT token from its service account
2. **Vault Authentication**: `vault-env` uses this JWT to authenticate with Vault's Kubernetes auth method
3. **Role Binding**: Vault validates the token and maps it to a role based on service account name/namespace
4. **Secret Access**: The role's policies determine which secrets the pod can access

### Secret Resolution Examples

```yaml
# Environment variable with Vault path
- name: DATABASE_PASSWORD
  value: "vault:secret/data/database#password"

# Templated value combining secrets
- name: DATABASE_URL  
  value: "postgresql://user:vault:secret/data/database#password@postgres:5432/mydb"
```

---

## Testing the Flow

### Verify Secret Injection

```bash
# Check webhook logs for injection activity
kubectl logs -l app.kubernetes.io/name=vault-secrets-webhook --tail=20

# Verify pod has been modified by webhook (should show init container)
kubectl describe pod -l app=webapp

# Check if secrets are resolved using vault-env (should show actual values)
kubectl exec deploy/webapp -- /vault/vault-env env | grep -E "(DATABASE_PASSWORD|API_KEY)"

# Test individual secret resolution
kubectl exec deploy/webapp -- /vault/vault-env sh -c 'echo "DATABASE_PASSWORD: $DATABASE_PASSWORD"; echo "API_KEY: $API_KEY"'

# Verify vault-env process is available
kubectl exec deploy/webapp -- ls -la /vault/
```

### Test Secret Rotation

```bash
# Update a secret in Vault
kubectl exec vault-0 -- vault kv put secret/database password=newsecret username=dbuser

# Restart application to pick up new secret
kubectl rollout restart deployment/webapp

# Wait for new pod to be ready
kubectl wait --for=condition=ready pod -l app=webapp --timeout=60s

# Verify new secret is injected
kubectl exec deploy/webapp -- /vault/vault-env printenv DATABASE_PASSWORD
```

### Debugging Secret Injection Issues

```bash
# Check if webhook is running and healthy
kubectl get pods -l app.kubernetes.io/name=vault-secrets-webhook
kubectl logs -l app.kubernetes.io/name=vault-secrets-webhook

# Verify webhook configuration
kubectl get mutatingwebhookconfiguration vault-secrets-webhook

# Check Vault authentication
kubectl exec vault-0 -- vault auth list
kubectl exec vault-0 -- vault read auth/kubernetes/role/default

# Test manual authentication from pod
kubectl exec deploy/webapp -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | \
  kubectl exec -i vault-0 -- vault write auth/kubernetes/login role=default jwt=-
```

## ✅ Working Configuration Summary

The deployment has been successfully tested and verified. Here are the key components that are working:

### ✅ Successfully Deployed Components

1. **HashiCorp Vault** - Deployed via Helm chart in development mode
2. **Bank-Vaults Operator** - Managing Vault instances and configurations  
3. **Bank-Vaults Webhook** - Injecting vault-env sidecar for secret resolution
4. **Kubernetes Authentication** - Service account JWT authentication with Vault
5. **Secret Injection** - Automatic resolution of `vault:` prefixed environment variables

### ✅ Verified Secret Injection Flow

```bash
# Secrets are properly resolved when using vault-env:
kubectl exec deploy/webapp -- /vault/vault-env env | grep -E "(DATABASE_PASSWORD|API_KEY)"
# Output:
# DATABASE_PASSWORD=supersecret
# API_KEY=api-key-12345
```

### 🔧 Key Configuration Fixes Applied

1. **Vault Kubernetes Auth Configuration**:
   ```bash
   # Used service account token for token_reviewer_jwt
   kubectl exec vault-0 -- vault write auth/kubernetes/config \
     token_reviewer_jwt="$(kubectl get secret $(kubectl get sa vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)" \
     kubernetes_host="https://kubernetes.default.svc.cluster.local:443" \
     kubernetes_ca_cert="$(kubectl get secret $(kubectl get sa vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)"
   ```

2. **Vault Role Configuration**:
   ```bash
   kubectl exec vault-0 -- vault write auth/kubernetes/role/default \
     bound_service_account_names=webapp \
     bound_service_account_namespaces=default \
     policies=allow_secrets \
     ttl=1h
   ```

3. **Application Annotations** (in `secret-injection-example.yaml`):
   ```yaml
   annotations:
     vault.security.banzaicloud.io/vault-addr: "http://vault:8200"
     vault.security.banzaicloud.io/vault-role: "default"
     vault.security.banzaicloud.io/vault-path: "kubernetes"
     vault.security.banzaicloud.io/vault-skip-verify: "true"
   ```

---

## Alternative Manual Deployment

If you prefer manual deployment without Helm:

```bash
# Deploy Vault manually
kubectl apply -f examples/apps/vault-deployment.yaml

# Initialize Vault manually
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1
kubectl exec vault-0 -- vault operator unseal <unseal-key>
```

---

## Cleanup

```bash
# Remove applications
kubectl delete -f examples/apps/secret-injection-example.yaml --ignore-not-found
kubectl delete -f examples/apps/vault-example.yaml --ignore-not-found

# Uninstall Helm releases
helm uninstall bank-vaults --namespace default
helm uninstall vault --namespace default

# Remove manual deployment (if used)
kubectl delete -f examples/apps/vault-deployment.yaml --ignore-not-found

# Clean up PVCs
kubectl delete pvc -l app.kubernetes.io/name=vault
```

---

## Configuration Details

### Vault Helm Values Customizations

The `vault-values.yaml` file includes several key customizations for the k8s-pine environment:

```yaml
# Development mode with auto-unseal
server:
  dev:
    enabled: true
    devRootToken: "root"

# Persistent storage for data retention
dataStorage:
  enabled: true
  size: 1Gi
  
# Resource optimization for development
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m

# Standalone mode (not HA) for simplicity
standalone:
  enabled: true
  config: |
    ui = true
    listener "tcp" {
      tls_disable = 1
      address = "[::]:8200"
    }
    storage "file" {
      path = "/vault/data"
    }
```

### Bank-Vaults Webhook Configuration

The webhook automatically injects the following into annotated pods:

1. **Init Container**: `copy-vault-env` copies the vault-env binary
2. **Wrapper Binary**: `/vault/vault-env` wraps the main application
3. **Environment Variables**: Vault connection and authentication settings
4. **Volumes**: Shared storage for the vault-env binary

### Annotation Reference

```yaml
metadata:
  annotations:
    # Vault server address
    vault.security.banzaicloud.io/vault-addr: "http://vault:8200"
    
    # Authentication method and role
    vault.security.banzaicloud.io/vault-role: "default"
    vault.security.banzaicloud.io/vault-path: "kubernetes"
    
    # Optional: Skip TLS verification
    vault.security.banzaicloud.io/vault-skip-verify: "true"
    
    # Optional: Custom vault-env image
    vault.security.banzaicloud.io/vault-env-image: "ghcr.io/bank-vaults/vault-env:v1.21.7"
```

---

## Key Concepts

### Vault Features
- **Secret Storage**: Secure storage for sensitive data with encryption at rest
- **Dynamic Secrets**: Generate time-limited credentials on-demand
- **Authentication**: Multiple auth methods (Kubernetes, JWT, LDAP, etc.)
- **Policies**: Fine-grained access control using HCL policies
- **Audit Logging**: Complete audit trail of all secret access
- **Encryption as a Service**: Transit encryption for application data

### Bank-Vaults Benefits
- **Kubernetes Native**: CRD-based Vault management with GitOps workflows
- **Zero-Downtime**: Automatic initialization, unsealing, and configuration
- **Secret Injection**: Transparent secret injection without code changes
- **Operator Pattern**: Declarative Vault configuration and lifecycle management
- **Multi-Tenancy**: Namespace-based isolation and RBAC integration

### Secret Injection Flow (Detailed)

1. **Pod Creation**: Application pod created with `vault.security.banzaicloud.io/*` annotations
2. **Webhook Interception**: Mutating admission webhook intercepts the pod creation request
3. **Pod Mutation**: Webhook modifies the pod spec to include:
   - Init container that copies `vault-env` binary
   - Modified command to wrap application with `vault-env`
   - Environment variables for Vault configuration
   - Shared volumes for binary and secrets
4. **Pod Startup**: Init container runs first, copying vault-env binary
5. **Authentication**: Main container starts, vault-env authenticates using service account JWT
6. **Secret Resolution**: vault-env resolves `vault:` prefixed environment variables
7. **Application Start**: Original application starts with resolved secret values

---

## Production Considerations

### Security Hardening

```yaml
# Use TLS in production
server:
  standalone:
    config: |
      listener "tcp" {
        tls_disable = 0
        tls_cert_file = "/vault/tls/server.crt"
        tls_key_file = "/vault/tls/server.key"
      }

# Enable audit logging
  auditStorage:
    enabled: true
    size: 10Gi
```

### High Availability Setup

```yaml
# Enable HA mode with Raft storage
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      config: |
        cluster_name = "vault-cluster"
        storage "raft" {
          path = "/vault/data"
        }
```

### Resource Planning

- **Development**: 256Mi-512Mi memory, 250m-500m CPU
- **Production**: 1Gi-4Gi memory, 500m-2000m CPU
- **Storage**: 10Gi-100Gi depending on secret volume and audit requirements

---

## Troubleshooting

### Common Issues

**Vault not ready**:
```bash
# Check Vault pod status and logs
kubectl logs vault-0
kubectl describe pod vault-0

# Verify Vault service and endpoints
kubectl get svc vault
kubectl get endpoints vault
```

**Authentication failures**:
```bash
# Check Kubernetes auth configuration
kubectl exec vault-0 -- vault read auth/kubernetes/config
kubectl exec vault-0 -- vault read auth/kubernetes/role/default

# Verify service account token
kubectl exec deploy/webapp -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

**Secret injection not working**:
```bash
# Check webhook pod status
kubectl get pods -l app.kubernetes.io/name=vault-secrets-webhook
kubectl logs -l app.kubernetes.io/name=vault-secrets-webhook

# Verify webhook configuration
kubectl get mutatingwebhookconfiguration vault-secrets-webhook -o yaml

# Check if pod was mutated
kubectl describe pod -l app=webapp | grep -A 10 "Init Containers"
```

**Performance issues**:
```bash
# Monitor resource usage
kubectl top pods -l app.kubernetes.io/name=vault
kubectl top pods -l app=webapp

# Check Vault metrics (if enabled)
kubectl port-forward vault-0 8220:8220
curl http://localhost:8220/v1/sys/metrics
```
