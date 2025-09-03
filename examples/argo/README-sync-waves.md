# ArgoCD Sync Waves with Helm Charts

This document demonstrates ArgoCD sync waves using the Helm charts from `examples/helm/`. Sync waves control the order of resource deployment, ensuring dependencies are satisfied before dependent applications start.

## 🌊 Sync Wave Applications

The following applications demonstrate proper deployment ordering using sync waves:

### Wave -1: Infrastructure Setup
- **`helm-namespace-setup`** - Creates required namespaces
- **Sync Wave**: `-1` (runs first)
- **Purpose**: Ensures namespaces exist before applications deploy

### Wave 1: Simple MySQL
- **`mysql-simple`** - Deploys MySQL using remote Bitnami chart
- **Sync Wave**: `1`
- **Namespace**: `mysql-simple`
- **Features**: Basic MySQL with custom values

### Wave 2: MySQL with Initialization
- **`mysql-with-init`** - Deploys custom Helm chart with hooks
- **Sync Wave**: `2`
- **Namespace**: `mysql-with-init`
- **Features**: MySQL + database initialization via Helm hooks

### Wave 3: Test Clients
- **`helm-test-client`** - Deploys connectivity test pods
- **Sync Wave**: `3` (runs last)
- **Namespace**: `helm-test`
- **Purpose**: Validates database connectivity

## 🚀 Quick Deployment

Deploy all sync wave applications:

```bash
# Deploy in order (sync waves handle sequencing automatically)
kubectl apply -f examples/argo/helm-namespace-setup.yaml
kubectl apply -f examples/argo/helm-mysql-simple.yaml
kubectl apply -f examples/argo/helm-mysql-with-init.yaml
kubectl apply -f examples/argo/helm-test-client.yaml

# Or deploy the app-of-apps pattern
kubectl apply -f examples/argo/helm-app-of-apps.yaml
```

## 📊 Monitoring Deployment

Check application status:
```bash
# View all Helm applications
kubectl get applications -n argo | grep helm

# Check sync waves execution order
kubectl get applications -n argo -o custom-columns="NAME:.metadata.name,WAVE:.metadata.annotations.argocd\.argoproj\.io/sync-wave,STATUS:.status.sync.status,HEALTH:.status.health.status"

# Monitor namespaces creation
kubectl get namespaces | grep -E "(mysql|helm-test)"
```

## 🔍 Testing Connectivity

Test database connections:

```bash
# Test simple MySQL
kubectl exec -it mysql-simple-0 -n mysql-simple -- mysql -utestuser -ptestpass123 testdb -e "SELECT 'Simple MySQL OK!' as status;"

# Test MySQL with initialization hooks
kubectl exec -it mysql-app-0 -n mysql-with-init -- mysql -utestuser -ptestpass123 testdb -e "
SELECT 'MySQL with Init OK!' as status;
SHOW TABLES;
SELECT COUNT(*) as users FROM users;
SELECT COUNT(*) as products FROM products;
"

# Check test client pods
kubectl get pods -n helm-test
kubectl logs mysql-connectivity-test-<pod-id> -n helm-test
```

## 📁 File Structure

```
examples/argo/
├── helm-namespace-setup.yaml      # Wave -1: Namespace creation
├── helm-mysql-simple.yaml         # Wave 1: Simple MySQL
├── helm-mysql-with-init.yaml      # Wave 2: MySQL with hooks
├── helm-test-client.yaml          # Wave 3: Test clients
├── helm-app-of-apps.yaml          # App-of-apps pattern
└── manifests/
    ├── namespaces/
    │   └── mysql-namespaces.yaml  # Namespace definitions
    └── test-clients/
        └── mysql-test-pods.yaml   # Test pod definitions
```

## 🔧 Sync Wave Configuration

Each application uses the `argocd.argoproj.io/sync-wave` annotation:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mysql-simple
  namespace: argo
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deployment order
spec:
  # Application specification
```

### Sync Wave Order
- **Negative numbers** (`-1`, `-2`): Infrastructure, prerequisites
- **Zero** (`0`): Default wave if not specified
- **Positive numbers** (`1`, `2`, `3`): Applications, tests, validation

## 🎯 Key Features Demonstrated

### Multi-Source Applications
The `mysql-simple` application shows how to use multiple sources:
- Helm chart from Bitnami repository
- Values file from Git repository

```yaml
sources:
- chart: mysql
  repoURL: https://charts.bitnami.com/bitnami
  targetRevision: 11.1.15
  helm:
    valueFiles:
    - $values/examples/helm/mysql-values.yaml
- repoURL: https://github.com/voatsap/k8s-pine/
  targetRevision: main
  ref: values
```

### Custom Helm Charts
The `mysql-with-init` application deploys a custom chart with:
- MySQL dependency
- Helm hooks for database initialization
- Template-based configuration

### Automated Sync Policies
All applications use automated sync with:
- **Prune**: Remove resources not in Git
- **Self-heal**: Automatically fix drift
- **Create namespace**: Auto-create target namespaces

## 🧪 Validation Results

✅ **Namespace Setup**: All required namespaces created  
✅ **MySQL Simple**: Database accessible, basic functionality working  
✅ **MySQL with Init**: Database accessible, initialization hooks executed  
✅ **Test Clients**: Connectivity validation successful  

## 🔄 Cleanup

Remove all sync wave applications:

```bash
# Delete applications (in reverse order)
kubectl delete -f examples/argo/helm-test-client.yaml
kubectl delete -f examples/argo/helm-mysql-with-init.yaml
kubectl delete -f examples/argo/helm-mysql-simple.yaml
kubectl delete -f examples/argo/helm-namespace-setup.yaml

# Clean up persistent volumes if needed
kubectl delete pvc -n mysql-simple --all
kubectl delete pvc -n mysql-with-init --all

# Remove namespaces
kubectl delete namespace mysql-simple mysql-with-init helm-test
```

## 📚 Learning Outcomes

This example demonstrates:
- **Sync Wave Ordering**: Control deployment sequence
- **Multi-Source Apps**: Combine Helm charts with Git repositories
- **Custom Helm Charts**: Create charts with dependencies and hooks
- **Automated Sync**: Self-healing and drift detection
- **Testing Strategy**: Validate deployments with test clients
- **App-of-Apps Pattern**: Manage multiple related applications

## 🔗 Related Documentation

- [ArgoCD Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [Helm Charts Guide](../helm/README.md)
- [ArgoCD Installation](README.md)
