# ArgoCD ApplicationSets Examples

This document demonstrates ArgoCD ApplicationSets using different generators to manage applications at scale. ApplicationSets automatically generate and manage multiple ArgoCD Applications based on templates and generators.

## 🎯 ApplicationSet Examples

### 1. List Generator - Multi-Environment MySQL
**File**: `appset-simple-list.yaml`
- **Generator**: List with predefined environments
- **Applications**: 3 (dev, staging, prod)
- **Features**: Different resource allocations per environment

```bash
kubectl apply -f examples/argo/appset-simple-list.yaml
```

### 2. Git Directory Generator - Environment Configs
**File**: `appset-git-generator.yaml`
- **Generator**: Git directories (`examples/argo/appset-environments/*`)
- **Applications**: 3 (based on Git directory structure)
- **Features**: Uses values files from Git repository

```bash
kubectl apply -f examples/argo/appset-git-generator.yaml
```

### 3. Matrix Generator - Environment × Tier × Version
**File**: `appset-matrix-generator.yaml`
- **Generator**: Matrix combining multiple dimensions
- **Applications**: 12 (3 envs × 2 tiers × 2 versions)
- **Features**: Cartesian product of parameters

```bash
kubectl apply -f examples/argo/appset-matrix-generator.yaml
```

### 4. Cluster Generator - Multi-Cluster Deployment
**File**: `appset-cluster-generator.yaml`
- **Generator**: Cluster labels and metadata
- **Applications**: Based on registered clusters
- **Features**: Deploy to multiple Kubernetes clusters

### 5. Pull Request Generator - PR Environments
**File**: `appset-pull-request.yaml`
- **Generator**: GitHub pull requests
- **Applications**: Dynamic based on active PRs
- **Features**: Automatic PR environment creation/cleanup

## 📊 Current Deployment Status

After deploying the ApplicationSets, you should see:

```bash
# Check ApplicationSets
kubectl get applicationsets -n argo

# Check generated Applications
kubectl get applications -n argo | grep mysql

# Check created namespaces
kubectl get namespaces | grep mysql
```

### Expected Applications:
- **List Generator**: `mysql-appset-dev`, `mysql-appset-staging`, `mysql-appset-prod`
- **Git Generator**: `mysql-dev`, `mysql-staging`, `mysql-prod`
- **Matrix Generator**: 12 apps like `mysql-dev-frontend-8.0`, `mysql-prod-backend-8.4`, etc.

## 🧪 Testing ApplicationSets

### Test List Generator Applications
```bash
# Test dev environment
kubectl exec -it mysql-appset-dev-0 -n mysql-appset-dev -- mysql -udevuser -pdevPass123 devdb -e "SELECT 'Dev Connected!' as status;"

# Test staging environment
kubectl exec -it mysql-appset-staging-0 -n mysql-appset-staging -- mysql -ustaginguser -pstagingPass123 stagingdb -e "SELECT 'Staging Connected!' as status;"

# Test prod environment
kubectl exec -it mysql-appset-prod-0 -n mysql-appset-prod -- mysql -uproduser -pprodPass123 proddb -e "SELECT 'Prod Connected!' as status;"
```

### Test Git Generator Applications
```bash
# Test applications created from Git directories
kubectl exec -it mysql-dev-0 -n mysql-dev -- mysql -udevuser -pdevPass123 devdb -e "SELECT 'Git Dev Connected!' as status;"

kubectl exec -it mysql-staging-0 -n mysql-staging -- mysql -ustaginguser -pstagingPass123 stagingdb -e "SELECT 'Git Staging Connected!' as status;"

kubectl exec -it mysql-prod-0 -n mysql-prod -- mysql -uproduser -pprodPass123 proddb -e "SELECT 'Git Prod Connected!' as status;"
```

### Test Matrix Generator Applications
```bash
# Test one of the matrix-generated applications
kubectl get pods -n mysql-dev-frontend
kubectl exec -it mysql-dev-frontend-8-0-0 -n mysql-dev-frontend -- mysql -udev_frontend_user -pdevfrontendPass123 dev_frontend_db -e "SELECT 'Matrix App Connected!' as status;"
```

## 🔧 ApplicationSet Configuration Patterns

### Template Variables
ApplicationSets use Go template syntax for variable substitution:

```yaml
template:
  metadata:
    name: mysql-{{.env}}  # Simple variable
    name: mysql-{{.path.basename}}  # Git path basename
  spec:
    destination:
      namespace: "{{.namespace}}"
    source:
      helm:
        parameters:
        - name: auth.database
          value: "{{.env}}db"
```

### Conditional Logic
```yaml
parameters:
- name: primary.persistence.size
  value: "{{if eq .env \"prod\"}}10Gi{{else}}2Gi{{end}}"
- name: secondary.replicaCount
  value: "{{if eq .env \"prod\"}}1{{else}}0{{end}}"
```

### Multi-Source Applications
```yaml
sources:
- chart: mysql
  repoURL: https://charts.bitnami.com/bitnami
  targetRevision: 11.1.15
  helm:
    valueFiles:
    - $values/{{.path}}/values.yaml
- repoURL: https://github.com/voatsap/k8s-pine/
  targetRevision: main
  ref: values
```

## 📁 Environment Configuration Structure

```
examples/argo/appset-environments/
├── dev/
│   └── values.yaml      # Dev-specific Helm values
├── staging/
│   └── values.yaml      # Staging-specific Helm values
└── prod/
    └── values.yaml      # Production-specific Helm values
```

Each `values.yaml` contains environment-specific configuration:

```yaml
environment: dev
database:
  name: devdb
  user: devuser
  password: devPass123
resources:
  requests:
    memory: 256Mi
    cpu: 250m
persistence:
  size: 2Gi
```

## 🎛️ Generator Types Comparison

| Generator | Use Case | Applications | Dynamic |
|-----------|----------|-------------|---------|
| **List** | Fixed environments | Static count | No |
| **Git** | Config-driven | Based on Git structure | Yes |
| **Matrix** | Multi-dimensional | Cartesian product | No |
| **Cluster** | Multi-cluster | Per cluster | Yes |
| **Pull Request** | PR environments | Per active PR | Yes |

## 🔄 ApplicationSet Management

### View ApplicationSet Status
```bash
# List all ApplicationSets
kubectl get applicationsets -n argo

# Describe specific ApplicationSet
kubectl describe applicationset mysql-simple-environments -n argo

# Check generated applications
kubectl get applications -n argo -l argocd.argoproj.io/application-set-name=mysql-simple-environments
```

### Update ApplicationSet
```bash
# Edit ApplicationSet
kubectl edit applicationset mysql-simple-environments -n argo

# Apply changes
kubectl apply -f examples/argo/appset-simple-list.yaml
```

### Delete ApplicationSet
```bash
# Delete ApplicationSet (also deletes generated applications)
kubectl delete applicationset mysql-simple-environments -n argo

# Clean up namespaces if needed
kubectl delete namespace mysql-appset-dev mysql-appset-staging mysql-appset-prod
```

## 🧹 Cleanup All ApplicationSets

```bash
# Delete all ApplicationSets
kubectl delete -f examples/argo/appset-simple-list.yaml
kubectl delete -f examples/argo/appset-git-generator.yaml
kubectl delete -f examples/argo/appset-matrix-generator.yaml

# Clean up namespaces
kubectl delete namespace $(kubectl get ns -o name | grep mysql | cut -d/ -f2)

# Clean up PVCs
kubectl delete pvc --all -n mysql-appset-dev
kubectl delete pvc --all -n mysql-appset-staging
kubectl delete pvc --all -n mysql-appset-prod
```

## 🎓 Learning Outcomes

This example demonstrates:
- **Scalable Application Management**: Manage dozens of applications with single ApplicationSet
- **Template-Driven Configuration**: Use Go templates for dynamic application generation
- **Git-Driven Operations**: Automatically sync applications based on Git repository structure
- **Multi-Dimensional Deployment**: Matrix generator for complex deployment scenarios
- **Environment Consistency**: Ensure consistent configuration across environments
- **Automated Lifecycle**: Applications automatically created/updated/deleted based on generators

## 🔗 Related Documentation

- [ArgoCD ApplicationSets](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [ApplicationSet Generators](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators/)
- [Sync Waves Examples](README-sync-waves.md)
- [ArgoCD Installation](README.md)
