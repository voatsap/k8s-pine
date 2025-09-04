# Helm Deployment Guide: Remote Charts vs Custom Charts

This guide demonstrates two approaches to deploying MySQL with Helm: using remote charts directly and creating custom charts with dependencies and hooks.

## Learning Objectives

By completing this guide, you will learn:
- How to work with remote Helm charts
- How to inspect and customize chart values
- How to create custom charts with dependencies
- How to implement Helm hooks for initialization tasks
- How to use dry-run testing and chart validation
- How to manage chart releases and upgrades

## Guide Structure

This guide is organized into two main approaches:

### **Approach 1: Working with Remote Charts**
- Simple deployment using external charts
- Custom values files for configuration
- Direct chart usage without modifications

### **Approach 2: Custom Charts with Dependencies and Hooks**
- Creating your own chart with dependencies
- Implementing Helm hooks for database initialization
- Template-based configuration and naming
- Chart packaging and distribution

## Prerequisites & Environment Setup

### Check Helm and Kubernetes Environment

```bash
# Check Helm version
helm version

# Check current Kubernetes context
kubectl config current-context

# Verify cluster connectivity
kubectl cluster-info

# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

---

# Approach 1: Working with Remote Charts

This approach uses external Helm charts directly with custom values files.

## Files for Remote Chart Approach

```
mysql-values.yaml                # Custom values for MySQL chart
README.md                        # This guide
```

## Step 1: Chart Discovery and Inspection

```bash
# Search for MySQL charts
helm search repo mysql

# View chart information
helm show chart bitnami/mysql
helm show values bitnami/mysql

# Pull chart locally for detailed inspection (optional)
helm pull bitnami/mysql --untar
ls mysql/
rm -rf mysql/ mysql-*.tgz  # cleanup
```

## Step 2: Create Custom Values File

Create `mysql-values.yaml`:

```yaml
auth:
  rootPassword: "rootpassword123"
  database: "testdb"
  username: "testuser"
  password: "testpass123"

primary:
  persistence:
    enabled: true
    size: 2Gi
  
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 250m
      memory: 256Mi

secondary:
  replicaCount: 0

metrics:
  enabled: false
```

## Step 3: Deploy MySQL with Remote Chart

```bash
# Test configuration with dry-run
helm install mysql bitnami/mysql -f mysql-values.yaml --dry-run --debug

# Deploy MySQL
helm install mysql bitnami/mysql -f mysql-values.yaml

# Monitor deployment
kubectl get pods -w -l app.kubernetes.io/name=mysql
```

## Step 4: Test Connection

```bash
# Test connection directly (most reliable method)
kubectl exec -it mysql-0 -- mysql -utestuser -ptestpass123 testdb -e "SELECT 'Connected!' as status;"

# Alternative: Test via service (may require network policies)
kubectl run mysql-client --rm -it --restart=Never --image=mysql:8.0 -- \
  mysql -hmysql -utestuser -ptestpass123 testdb -e "SELECT 'Connected!' as status;"

# Connect interactively
kubectl exec -it mysql-0 -- mysql -utestuser -ptestpass123 testdb
```

## Cleanup Remote Chart Deployment

```bash
helm uninstall mysql
kubectl delete pvc data-mysql-0
```

---

# Approach 2: Custom Charts with Dependencies and Hooks

This approach creates a custom chart that includes MySQL as a dependency and adds initialization hooks.

## Files for Custom Chart Approach

```
mysql-with-init/                 # Custom Helm chart
├── Chart.yaml                   # Chart metadata with MySQL dependency
├── values.yaml                  # Chart configuration values
└── templates/
    ├── _helpers.tpl             # Template helpers
    └── test-db-hook.yaml        # Database initialization hook
```

## Step 1: Inspect Custom Chart Structure

```bash
# Navigate to examples/helm directory
cd examples/helm

# Examine the custom chart structure
ls -la mysql-with-init/
cat mysql-with-init/Chart.yaml
cat mysql-with-init/values.yaml
```

## Step 2: Prepare Chart Dependencies

```bash
# Navigate to chart directory
cd mysql-with-init

# Download dependencies
helm dependency update

# Verify dependencies are downloaded
ls charts/
```

## Step 3: Test and Deploy Custom Chart

```bash
# Test with dry-run (CRITICAL STEP)
helm install mysql-app . --dry-run --debug

# Validate chart syntax
helm lint .

# Deploy the custom chart
helm install mysql-app .

# Monitor deployment
kubectl get pods -w -l app.kubernetes.io/instance=mysql-app

# Watch hook execution
kubectl get jobs -w
kubectl logs job/mysql-app-mysql-with-init-test-db-init -f
```

## Step 4: Test Database with Hook Data

```bash
# Test connection and verify hook created test data (direct method)
kubectl exec -it mysql-app-0 -- mysql -utestuser -ptestpass123 testdb -e "
SHOW TABLES;
SELECT * FROM users;
SELECT * FROM products;
"

# Alternative: Test via service (may require network policies)
kubectl run mysql-client --rm -it --restart=Never --image=mysql:8.0 -- \
  mysql -hmysql-app-mysql -utestuser -ptestpass123 testdb -e "
  SHOW TABLES;
  SELECT * FROM users;
  SELECT * FROM products;
  "
```

## Step 5: Chart Management

```bash
# Check release status
helm status mysql-app

# Get release values
helm get values mysql-app

# Upgrade chart (triggers hook again)
helm upgrade mysql-app .

# View release history
helm history mysql-app
```

## Cleanup Custom Chart Deployment

```bash
# Navigate back to examples/helm directory
cd ..

# Remove everything
helm uninstall mysql-app
kubectl delete pvc data-mysql-app-mysql-0
```

---

# Understanding Helm Hooks

## What Are Helm Hooks?

Helm hooks are regular Kubernetes resources (Jobs, Pods, ConfigMaps, etc.) that execute at specific points in a release lifecycle. They are defined by adding special annotations to any Kubernetes resource manifest.

## Hook Implementation in Custom Charts

In our `mysql-with-init/templates/test-db-hook.yaml`, the hook is a templated Kubernetes Job:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mysql-with-init.fullname" . }}-test-db-init
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  # Job specification with templated values
```

## Hook Annotations Explained

- **`helm.sh/hook`**: `post-install,post-upgrade` - Runs after successful installation or upgrade
- **`helm.sh/hook-weight`**: `"1"` - Execution order (lower numbers run first)
- **`helm.sh/hook-delete-policy`**: Auto-cleanup behavior

## Hook vs Standalone Resources

| Aspect | Remote Chart | Custom Chart with Hooks |
|--------|--------------|-------------------------|
| **Hook Integration** | Not possible | Built into chart templates |
| **Initialization** | Manual post-deployment | Automatic via hooks |
| **Templating** | Static values only | Dynamic Helm templating |
| **Lifecycle Management** | Manual coordination | Automatic with release |

---

# Common Helm Commands

## Release Management
```bash
# List all releases
helm list

# Get release status
helm status <release-name>

# Get release history
helm history <release-name>

# Get release values
helm get values <release-name>
```

## Chart Operations
```bash
# Search for charts
helm search repo <keyword>

# Show chart information
helm show chart <chart-name>
helm show values <chart-name>

# Pull chart locally
helm pull <chart-name> --untar
```

## Testing and Debugging
```bash
# Dry-run deployment
helm install <release> <chart> --dry-run --debug

# Template generation
helm template <release> <chart>

# Chart validation
helm lint <chart-path>
```

## Upgrade and Rollback
```bash
# Upgrade release
helm upgrade <release> <chart>

# Rollback to previous version
helm rollback <release>

# Rollback to specific revision
helm rollback <release> <revision>
```


#### 1. Helm Command Not Found
```bash
# Check if Helm is installed
which helm
helm version

# If not installed, install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
```

#### 2. Repository Issues
```bash
# Repository not found
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Check repositories
helm repo list
```

#### 3. Release Already Exists
```bash
# Check existing releases
helm list

# Uninstall if needed
helm uninstall mysql

# Or use different name
helm install mysql-new bitnami/mysql -f mysql-values.yaml
```

## Learning Exercises

### Exercise 1: Chart Exploration
1. Pull the MySQL chart locally
2. Examine the templates directory
3. Identify different Kubernetes resources created
4. Compare default values with your custom values

### Exercise 2: Values Customization
1. Modify `mysql-values.yaml` to change resource limits
2. Use dry-run to see the changes
3. Apply the changes and verify

### Exercise 3: Hook Understanding
1. Examine the `test-db-hook.yaml` file
2. Understand the hook annotations
3. Create a new hook that runs before installation (pre-install)


### Exercise 4: Troubleshooting Practice
1. Intentionally break the configuration
2. Use Helm and kubectl commands to diagnose issues
3. Fix the problems and redeploy

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Bitnami MySQL Chart](https://github.com/bitnami/charts/tree/main/bitnami/mysql)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
