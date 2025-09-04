# Velero Backup and Restore Solution

This directory contains a comprehensive backup and restore solution using Velero for the k8s-pine cluster.

## Overview

Velero is an open-source tool for safely backing up and restoring, performing disaster recovery, and migrating Kubernetes cluster resources and persistent volumes.

## Installation Guide

### Prerequisites

- Kubernetes cluster (k8s-pine)
- Helm 3.x installed
- kubectl configured and connected to your cluster

### Step 1: Install Velero CLI

#### macOS (using Homebrew)
```bash
brew install velero
```

#### macOS (manual installation)
```bash
# Download latest release
VELERO_VERSION="v1.12.1"
curl -fsSL -o velero-${VELERO_VERSION}-darwin-amd64.tar.gz \
    https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-darwin-amd64.tar.gz

# Extract and install
tar -xzf velero-${VELERO_VERSION}-darwin-amd64.tar.gz
sudo mv velero-${VELERO_VERSION}-darwin-amd64/velero /usr/local/bin/
rm -rf velero-${VELERO_VERSION}-darwin-amd64*

# Verify installation
velero version --client-only
```

#### Linux
```bash
# Download latest release
VELERO_VERSION="v1.12.1"
curl -fsSL -o velero-${VELERO_VERSION}-linux-amd64.tar.gz \
    https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz

# Extract and install
tar -xzf velero-${VELERO_VERSION}-linux-amd64.tar.gz
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/
rm -rf velero-${VELERO_VERSION}-linux-amd64*

# Verify installation
velero version --client-only
```

### Step 2: Install Velero Server with Helm

#### Add Velero Helm Repository
```bash
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update
```

#### Create Velero Namespace
```bash
kubectl create namespace velero
```

#### Install Velero with Helm
```bash
helm install velero vmware-tanzu/velero \
    --namespace velero \
    --version 5.2.0 \
    --create-namespace
```

### Step 3: Verify Installation

Check that Velero is running:
```bash
# Check pods
kubectl get pods -n velero

# Check Velero version (both client and server)
velero version

# Check backup locations
velero backup-location get

# Check volume snapshot locations
velero snapshot-location get
```

## Complete Installation and Testing Guide

### Step 4: Deploy Minio for PVC Storage

Create the Minio deployment with PVC storage:

```bash
# Apply Minio configuration (creates PVC, deployment, service, and setup job)
kubectl apply -f examples/velero/minio.yaml

# Wait for Minio to be ready
kubectl wait --for=condition=ready pod -l app=minio -n velero --timeout=120s

# Manually create the bucket (if setup job fails)
kubectl exec -n velero deployment/minio -- mc alias set velero http://localhost:9000 minio minio123
kubectl exec -n velero deployment/minio -- mc mb velero/velero-backups --ignore-existing
```

### Step 5: Install Velero Server with PVC Configuration

```bash
# Install/upgrade Velero with PVC values
helm upgrade velero vmware-tanzu/velero \
    --namespace velero \
    --version 5.2.0 \
    --values examples/velero/values.yaml

# Wait for Velero pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=velero -n velero --timeout=120s
```

## Testing and Verification

### Step 6: Verify Installation

```bash
# Check all pods are running
kubectl get pods -n velero

# Check Velero version (client and server)
velero version

# Verify backup storage location is available
velero backup-location get

# Check volume snapshot location
velero snapshot-location get

# Verify PVC is bound
kubectl get pvc -n velero
```

Expected output:
```
NAME      PROVIDER   BUCKET/PREFIX    PHASE       LAST VALIDATED   ACCESS MODE   DEFAULT
default   aws        velero-backups   Available   <timestamp>      ReadWrite     true
```

### Step 7: Create and Test Different Types of Backups

#### 1. Full Cluster Backup
Create a complete backup of all cluster resources:

```bash
# Create full cluster backup
velero backup create full-cluster-backup

# What to check after creation:
velero backup get
velero backup describe full-cluster-backup

# Expected: Status should be "Completed", check items backed up count
# Verify backup exists in storage
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/full-cluster-backup/
```

#### 2. Namespace-Specific Backup
Create backup of specific namespace(s):

```bash
# Backup single namespace
velero backup create default-namespace-backup --include-namespaces default

# Backup multiple namespaces
velero backup create multi-namespace-backup --include-namespaces default,kube-system,velero

# What to check:
velero backup describe default-namespace-backup
# Expected: Should show "Namespaces: Included: default"

# Check backup contents
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/default-namespace-backup/
```

#### 3. PVC and Volume Backup
Create backup including persistent volumes:

```bash
# Backup with PVC data (uses node agent for file-level backup)
velero backup create pvc-backup --include-namespaces default --default-volumes-to-fs-backup

# Backup specific PVCs only
velero backup create specific-pvc-backup --include-resources persistentvolumeclaims,persistentvolumes

# What to check:
velero backup describe pvc-backup
# Expected: Should show volume backup details in "Backup Volumes" section

# Check for pod volume backups
kubectl get podvolumebackups -n velero
```

#### 4. Resource-Specific Backup
Create backup of specific resource types:

```bash
# Backup only deployments and services
velero backup create apps-backup --include-resources deployments,services

# Backup with label selector
velero backup create labeled-backup --selector app=nginx

# What to check:
velero backup describe apps-backup
# Expected: Should show "Resources: Included: deployments, services"

velero backup describe labeled-backup
# Expected: Should show "Label selector: app=nginx"
```

#### 5. Backup Verification Commands
After creating any backup, always verify:

```bash
# 1. Check backup status and details
velero backup get
velero backup describe <backup-name>

# 2. Check backup logs for any issues
velero backup logs <backup-name>

# 3. Verify files are stored in Minio
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/<backup-name>/

# 4. Check backup size and file count
kubectl exec -n velero deployment/minio -- mc du velero/velero-backups/backups/<backup-name>/

# 5. For PVC backups, check pod volume backups
kubectl get podvolumebackups -n velero
kubectl describe podvolumebackup <pvb-name> -n velero
```

#### What Each Backup Should Contain

**Full Cluster Backup:**
- All namespaces and resources
- ConfigMaps, Secrets, Deployments, Services, etc.
- Cluster-scoped resources (ClusterRoles, etc.)
- Expected items: 800+ resources

**Namespace Backup:**
- Only resources from specified namespace(s)
- All resource types within those namespaces
- Expected items: varies by namespace content

**PVC Backup:**
- Persistent Volume Claims and Volumes
- File-level data from mounted volumes (if using node agent)
- Pod Volume Backup objects created

**Resource-Specific Backup:**
- Only the specified resource types
- Filtered by labels if selector used
- Expected items: depends on filter criteria

### Step 8: Test Restore Operations

```bash
# Create a restore from backup
velero restore create --from-backup test-backup

# List restore operations
velero restore get

# Check restore status
velero restore describe test-backup-<timestamp>

# View restore logs
velero restore logs test-backup-<timestamp>
```

### Step 9: Storage Verification

```bash
# Check PVC usage
kubectl get pvc -n velero
kubectl describe pvc minio-pvc -n velero

# Check Minio storage contents
kubectl exec -n velero deployment/minio -- mc du velero/velero-backups

# Access Minio console (optional)
kubectl port-forward -n velero svc/minio 9001:9001
# Then open http://localhost:9001 (minio/minio123)
```

## Basic Usage Examples

### Create Different Types of Backups
```bash
# Backup entire cluster
velero backup create full-cluster-backup

# Backup specific namespace
velero backup create app-backup --include-namespaces my-app

# Backup with custom TTL (time to live)
velero backup create temp-backup --ttl 24h0m0s

# Backup with labels selector
velero backup create labeled-backup --selector app=my-app
```

### Restore Operations
```bash
# Restore from backup
velero restore create --from-backup full-cluster-backup

# Restore to different namespace
velero restore create --from-backup app-backup --namespace-mappings my-app:my-app-restored

# Restore specific resources only
velero restore create --from-backup app-backup --include-resources deployments,services
```

### Backup Management
```bash
# List all backups
velero backup get

# Delete a backup
velero backup delete old-backup

# Get backup details
velero backup describe my-backup
```

## Tested Commands Summary

Here are the exact commands that were executed and tested successfully:

### Installation Commands
```bash
# Install Velero CLI
brew install velero

# Add Helm repository
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace velero

# Deploy Minio storage
kubectl apply -f examples/velero/minio.yaml
kubectl wait --for=condition=ready pod -l app=minio -n velero --timeout=120s

# Setup Minio bucket
kubectl exec -n velero deployment/minio -- mc alias set velero http://localhost:9000 minio minio123
kubectl exec -n velero deployment/minio -- mc mb velero/velero-backups --ignore-existing

# Install Velero server
helm upgrade velero vmware-tanzu/velero --namespace velero --version 5.2.0 --values examples/velero/values.yaml
```

### Verification Commands
```bash
# Check installation
kubectl get pods -n velero
velero version
velero backup-location get
velero snapshot-location get
kubectl get pvc -n velero
```

### Backup Testing Commands
```bash
# Create backups
velero backup create test-backup
velero backup create namespace-backup --include-namespaces default

# Check backup status
velero backup get
velero backup describe test-backup

# Verify storage
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/
kubectl exec -n velero deployment/minio -- mc ls velero/velero-backups/backups/test-backup/
```

### Restore Testing Commands
```bash
# Create restore
velero restore create --from-backup test-backup

# Check restore status
velero restore get
velero restore describe test-backup-20250904111429
```

## Sample Backup Manifests

The `manifests/` directory contains ready-to-use backup examples:

### Apply Sample Schedules and Backups

```bash
# Apply backup schedules (automated backups)
kubectl apply -f examples/velero/manifests/backup-schedule.yaml

# Apply PVC-specific backups
kubectl apply -f examples/velero/manifests/pvc-backup.yaml

# Apply namespace-specific backups
kubectl apply -f examples/velero/manifests/namespace-backup.yaml

# Check created schedules
velero schedule get

# Check created backups
velero backup get
```

### Available Manifest Files

**1. `backup-schedule.yaml`** - Automated backup schedules:
- Daily namespace backup (2 AM)
- Weekly full cluster backup (Sunday 1 AM)
- Hourly production backup
- Monthly archive backup

**2. `pvc-backup.yaml`** - PVC and volume backups:
- All PVCs with file-level data
- Namespace-specific PVC backups
- Storage class filtered backups
- Database PVC backups with hooks

**3. `namespace-backup.yaml`** - Namespace-specific backups:
- Single namespace backup
- Multi-namespace backup
- Production vs development backups
- Critical namespace backup with hooks

### Customize the Manifests

Edit the manifest files to match your environment:

```bash
# Edit namespace names
sed -i 's/production/your-prod-namespace/g' examples/velero/manifests/*.yaml

# Edit schedule times
sed -i 's/0 2 \* \* \*/0 3 \* \* \*/g' examples/velero/manifests/backup-schedule.yaml

# Edit retention periods
sed -i 's/720h0m0s/168h0m0s/g' examples/velero/manifests/*.yaml
```

## Configuration Files

This setup uses these configuration files:

1. **`minio.yaml`** - Deploys Minio with 100Gi PVC storage
2. **`values.yaml`** - Configures Velero to use Minio as S3-compatible backend
3. **`manifests/backup-schedule.yaml`** - Automated backup schedules
4. **`manifests/pvc-backup.yaml`** - PVC and volume backup examples
5. **`manifests/namespace-backup.yaml`** - Namespace-specific backup examples

## Troubleshooting

### Common Commands
```bash
# Get help
velero --help

# Check Velero logs
kubectl logs -n velero deployment/velero

# Check Minio logs
kubectl logs -n velero deployment/minio

# Check node agent logs
kubectl logs -n velero daemonset/node-agent

# Access Minio console
kubectl port-forward -n velero svc/minio 9001:9001
# Open http://localhost:9001 (minio/minio123)
```

### Version Compatibility
- **Velero CLI**: v1.16.2 (installed)
- **Velero Server**: v1.12.2 (Helm chart v5.2.0)
- **Note**: Client/server version mismatch is normal and functional

## Documentation

- [Official Velero Documentation](https://velero.io/docs/)
- [Velero GitHub Repository](https://github.com/vmware-tanzu/velero)
- [Helm Chart Documentation](https://github.com/vmware-tanzu/helm-charts/tree/main/charts/velero)
