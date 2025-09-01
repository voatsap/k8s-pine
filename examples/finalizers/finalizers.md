# Finalizers and Cascade Deletion Patterns

This example demonstrates Kubernetes finalizers and cascade deletion patterns for proper resource cleanup and dependency management.

---

## Contents

This guide contains examples of finalizers, cascade deletion policies, and owner references for managing resource lifecycles.

---

## Files

- `examples/finalizers/finalizer-crd.yaml` — CleanupJob CustomResourceDefinition
- `examples/finalizers/finalizer-rbac.yaml` — ServiceAccount, ClusterRole, ClusterRoleBinding
- `examples/finalizers/finalizer-deployment.yaml` — Finalizer controller deployment and script
- `examples/finalizers/finalizer-controller.sh` — Finalizer controller script source
- `examples/finalizers/cleanup-job-samples.yaml` — Sample CleanupJob resources and target resources
- `examples/finalizers/cascade-deletion-examples.yaml` — Owner references and cascade deletion examples

---

## Concepts

### Finalizers
- Finalizers prevent resource deletion until cleanup tasks complete
- Controllers watch for deletion timestamp and perform cleanup
- Finalizer removal allows actual deletion to proceed

### Cascade Deletion Policies
- **Foreground**: Delete dependents first, then owner
- **Background**: Delete owner immediately, dependents asynchronously  
- **Orphan**: Delete owner, leave dependents orphaned

### Owner References
- Automatic cleanup when owner is deleted
- `controller: true` - only one controller owner per resource
- `blockOwnerDeletion: true` - prevents owner deletion until dependent is removed

---

## Usage Demo

### Phase 1: Finalizer Controller Setup

1. **Install the CleanupJob CRD**

```bash
kubectl apply -f examples/finalizers/finalizer-crd.yaml
```

2. **Deploy the finalizer controller**

```bash
kubectl apply -f examples/finalizers/finalizer-rbac.yaml
kubectl apply -f examples/finalizers/finalizer-deployment.yaml
```

3. **Verify controller is running**

```bash
kubectl get deploy,pods
kubectl logs deploy/finalizer-controller -f
```

**Expected Output**: Controller should start and begin watching for CleanupJob resources.

### Phase 2: Finalizer Testing

4. **Create sample resources and CleanupJobs**

```bash
kubectl apply -f examples/finalizers/cleanup-job-samples.yaml
```

This creates:
- 3 CleanupJob custom resources
- 2 temporary ConfigMaps (`temp-config-1`, `temp-config-2`) with `environment=temp` labels
- 1 test Pod with `type=test` label
- 1 Secret with `cleanup=true` label

5. **Observe automatic finalizer addition**

```bash
kubectl get cleanupjobs
kubectl describe cleanupjob cleanup-temp-configs
```

**Expected Behavior**:
- Controller automatically adds `k8spatterns.io/cleanup-finalizer` to each CleanupJob
- Status is set to `Pending` with message "Waiting for deletion"
- Check logs: `kubectl logs deploy/finalizer-controller --tail=10`

6. **Test finalizer cleanup flow**

```bash
# Before deletion - verify target resources exist
kubectl get cm -l environment=temp
kubectl get pods -l type=test

# Delete a CleanupJob to trigger finalizer
kubectl delete cleanupjob cleanup-temp-configs
```

**Expected Flow**:
1. **Deletion Request**: CleanupJob gets `deletionTimestamp` but remains due to finalizer
2. **Controller Detection**: Controller detects deletion and starts cleanup
3. **Status Update**: Status changes to "Cleaning" 
4. **Resource Cleanup**: Target ConfigMaps with `environment=temp` are deleted
5. **Finalizer Removal**: Controller removes finalizer from CleanupJob
6. **Resource Deletion**: CleanupJob is finally deleted by Kubernetes

**Verification**:
```bash
# Verify target resources were cleaned up
kubectl get cm -l environment=temp  # Should return "No resources found"

# Verify CleanupJob was removed
kubectl get cleanupjobs  # Should not include cleanup-temp-configs
```

7. **Test additional cleanup scenarios**

```bash
# Test pod cleanup
kubectl delete cleanupjob cleanup-test-pods

# Verify pod was deleted
kubectl get pods -l type=test  # Should return "No resources found"
```

### Phase 3: Cascade Deletion Testing

8. **Create parent-child resource hierarchy**

```bash
kubectl apply -f examples/finalizers/cascade-deletion-examples.yaml
```

**Note**: Initial creation will fail for child resources due to empty owner reference UIDs. This is expected.

9. **Set up proper owner references**

```bash
# Create child resources without owner references first
kubectl create configmap child-config --from-literal=config.yaml="app:\n  name: parent-app\n  version: \"1.0\""
kubectl create secret generic child-secret --from-literal=password=password123
kubectl expose deployment parent-app --port=80 --name=parent-app-service

# Get parent UID and set owner references
PARENT_UID=$(kubectl get deployment parent-app -o jsonpath='{.metadata.uid}')

kubectl patch configmap child-config --type merge -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"name\":\"parent-app\",\"uid\":\"$PARENT_UID\",\"controller\":true,\"blockOwnerDeletion\":true}]}}"

kubectl patch secret child-secret --type merge -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"name\":\"parent-app\",\"uid\":\"$PARENT_UID\",\"controller\":true,\"blockOwnerDeletion\":false}]}}"

kubectl patch service parent-app-service --type merge -p "{\"metadata\":{\"ownerReferences\":[{\"apiVersion\":\"apps/v1\",\"kind\":\"Deployment\",\"name\":\"parent-app\",\"uid\":\"$PARENT_UID\",\"controller\":false,\"blockOwnerDeletion\":false}]}}"
```

10. **Verify owner reference setup**

```bash
kubectl get deployment,configmap,secret,service | grep -E "(parent-app|child-)"
kubectl get configmap child-config -o yaml | grep -A 10 ownerReferences
```

11. **Test cascade deletion policies**

```bash
# Background deletion (default) - parent deleted immediately, children cleaned up asynchronously
kubectl delete deployment parent-app --cascade=background

# Verify all resources are deleted
kubectl get deployment,configmap,secret,service | grep -E "(parent-app|child-)"
```

**Expected Cascade Flow**:
1. **Parent Deletion**: Deployment is deleted immediately
2. **Automatic Cleanup**: Kubernetes garbage collector detects orphaned children
3. **Child Deletion**: ConfigMap, Secret, and Service are automatically deleted
4. **Complete Cleanup**: All resources removed without manual intervention

**Alternative cascade policies** (recreate resources first):
```bash
# Foreground deletion - children deleted first, then parent
kubectl delete deployment parent-app --cascade=foreground

# Orphan deletion - parent deleted, children remain
kubectl delete deployment parent-app --cascade=orphan
```

### Phase 4: Cleanup

12. **Remove all test resources**

```bash
kubectl delete -f examples/finalizers/cleanup-job-samples.yaml --ignore-not-found
kubectl delete -f examples/finalizers/cascade-deletion-examples.yaml --ignore-not-found
kubectl delete -f examples/finalizers/finalizer-deployment.yaml
kubectl delete -f examples/finalizers/finalizer-rbac.yaml
kubectl delete -f examples/finalizers/finalizer-crd.yaml
kubectl delete clusterrolebinding finalizer-controller --ignore-not-found
kubectl delete clusterrole finalizer-controller --ignore-not-found
```

---

## Controller Implementation Details

### Finalizer Controller Flow

1. **Resource Watching**: Controller uses `kubectl get cleanupjobs -A --watch` to monitor all CleanupJob resources
2. **Finalizer Management**: Automatically adds `k8spatterns.io/cleanup-finalizer` to new CleanupJobs
3. **Deletion Detection**: Monitors `deletionTimestamp` to detect deletion requests
4. **Cleanup Execution**: Performs resource cleanup based on `resourceType` and `selector` fields
5. **Status Updates**: Updates CleanupJob status throughout the lifecycle
6. **Finalizer Removal**: Removes finalizer after successful cleanup to allow deletion

### Key Implementation Patterns

- **JSONPath Usage**: Uses `kubectl -o jsonpath` instead of full JSON parsing to avoid control character issues
- **Error Handling**: Graceful handling of missing resources and permission errors
- **Status Reporting**: Clear status messages for debugging and monitoring
- **Selector-Based Cleanup**: Flexible cleanup using Kubernetes label selectors

---

## Key Patterns

### Finalizer Implementation
1. Add finalizer to resource metadata
2. Watch for deletion timestamp
3. Perform cleanup operations
4. Remove finalizer to complete deletion

### Owner Reference Best Practices
- Use `controller: true` for primary owner relationship
- Set `blockOwnerDeletion: true` for critical dependencies
- Choose appropriate cascade deletion policy for your use case

### Cleanup Strategies
- **Finalizers**: For complex cleanup logic and external resources
- **Owner References**: For simple parent-child relationships
- **Custom Controllers**: For advanced lifecycle management
