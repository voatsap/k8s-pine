# Operator Pattern: ConfigWatcher Custom Resource

This example demonstrates a Kubernetes Operator that extends the Controller pattern by introducing a Custom Resource Definition (CRD). The operator watches ConfigMap changes and restarts workloads based on ConfigWatcher custom resources that define relationships between ConfigMaps and workloads.

---

## Contents

This guide contains description and usage for the Operator pattern. All manifests are split into separate files under `examples/controller/`.

---

## Files

- `examples/controller/operator/config-watcher-crd.yaml` — CustomResourceDefinition for ConfigWatcher
- `examples/controller/operator/operator-rbac.yaml` — ServiceAccount, ClusterRole, ClusterRoleBinding with CRD permissions
- `examples/controller/operator/operator-configmap.yaml` — ConfigMap embedding the operator script
- `examples/controller/operator/operator-deployment.yaml` — Deployment mounting and running the operator
- `examples/controller/operator/config-watcher-sample.yaml` — Sample ConfigWatcher custom resource
- `examples/controller/operator/webapp-sample.yaml` — Sample webapp ConfigMap, Deployment, Service
- `examples/controller/operator/operator.sh` — Operator script source

---

## How it works

- The operator watches ConfigMap changes across all namespaces
- When a ConfigMap changes, it checks for ConfigWatcher custom resources that reference that ConfigMap
- Each ConfigWatcher defines a `configMap` name and `selector` for workloads to restart
- The operator restarts matching workloads when their referenced ConfigMap changes
- The operator updates the ConfigWatcher status with monitoring information
- This provides a declarative way to manage config-driven restarts

---

## Usage Demo

1. Install the CRD

```bash
kubectl apply -f examples/controller/operator/config-watcher-crd.yaml
```

2. Verify CRD is registered

```bash
kubectl get crd configwatchers.k8spatterns.io
```

3. Deploy the operator

```bash
kubectl apply -f examples/controller/operator/operator-rbac.yaml
kubectl apply -f examples/controller/operator/operator-configmap.yaml
kubectl apply -f examples/controller/operator/operator-deployment.yaml
```

4. Deploy sample webapp

```bash
kubectl apply -f examples/controller/operator/webapp-sample.yaml
```

5. Verify operator and webapp are running

```bash
kubectl get deploy,pods
kubectl logs deploy/config-watcher-operator -f
```

6. Access the webapp

```bash
kubectl port-forward svc/webapp 8080:80
# Open http://localhost:8080 — should show: "Hello from the Operator pattern!"
```

7. Create ConfigWatcher custom resource

```bash
kubectl apply -f examples/controller/operator/config-watcher-sample.yaml
```

8. Verify ConfigWatcher was created

```bash
kubectl get configwatchers
kubectl describe configwatcher webapp-config-watcher
```

9. **Test the operator by changing ConfigMap**

```bash
# Watch operator logs in another terminal
kubectl logs deploy/config-watcher-operator -f

# Change the ConfigMap content
kubectl patch configmap webapp-config \
  --type merge -p '{"data":{"message":"Greets from your smooth operator!"}}'
```

- Watch operator logs; you should see it detect the ConfigMap change and restart workloads
- Refresh http://localhost:8080 — content should update to: "Greets from your smooth operator!"

10. Check ConfigWatcher status

```bash
kubectl get configwatcher webapp-config-watcher -o yaml
```

11. Cleanup

```bash
kubectl delete -f examples/controller/operator/config-watcher-sample.yaml
kubectl delete -f examples/controller/operator/webapp-sample.yaml
kubectl delete -f examples/controller/operator/operator-deployment.yaml
kubectl delete -f examples/controller/operator/operator-configmap.yaml
kubectl delete -f examples/controller/operator/operator-rbac.yaml
kubectl delete -f examples/controller/operator/config-watcher-crd.yaml
kubectl delete clusterrolebinding config-watcher-operator --ignore-not-found
kubectl delete clusterrole config-watcher-operator --ignore-not-found
```

---

## Operator vs Controller

**Controller Pattern:**
- Watches ConfigMaps directly
- Uses annotations on ConfigMaps to define restart behavior
- Simple and direct

**Operator Pattern:**
- Watches ConfigMap changes and checks for associated ConfigWatcher custom resources
- Separates configuration from behavior
- More declarative and Kubernetes-native
- Enables status reporting and lifecycle management
- Better for complex scenarios and multiple configurations

---

## ✅ Fixed Issues

### **Issue 1: Wrong Watch Target**
**Problem**: Original operator watched ConfigWatcher resources instead of ConfigMap changes
**Fix**: Changed to watch ConfigMap changes and then check for associated ConfigWatchers

### **Issue 2: Logic Flow**
**Problem**: Operator triggered on ConfigWatcher creation/modification, not ConfigMap changes
**Fix**: Implemented proper flow: ConfigMap change → find ConfigWatchers → restart workloads

### **Issue 3: Error Handling**
**Problem**: Poor error handling and status updates
**Fix**: Added proper error handling and meaningful status messages

---

## Troubleshooting

### **Operator not responding to ConfigMap changes**
```bash
# Check operator logs
kubectl logs deploy/config-watcher-operator --tail=20

# Verify ConfigWatcher exists and references correct ConfigMap
kubectl get configwatchers -o yaml

# Test ConfigMap change detection manually
kubectl patch configmap <configmap-name> --type merge -p '{"data":{"test":"value"}}'
```

### **Workloads not restarting**
```bash
# Check if deployments match the selector
kubectl get deploy -l <selector-from-configwatcher>

# Verify RBAC permissions
kubectl auth can-i rollout restart deployment --as=system:serviceaccount:default:config-watcher-operator

# Check for deployment restart errors in operator logs
kubectl logs deploy/config-watcher-operator | grep -i error
```

### **ConfigWatcher status not updating**
```bash
# Check if operator has permissions to patch ConfigWatcher resources
kubectl auth can-i patch configwatchers --as=system:serviceaccount:default:config-watcher-operator

# Verify ConfigWatcher CRD status subresource
kubectl get crd configwatchers.k8spatterns.io -o yaml | grep -A 5 status
```
