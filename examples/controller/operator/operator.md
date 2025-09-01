# Operator Pattern: ConfigWatcher Custom Resource

This example demonstrates a Kubernetes Operator that extends the Controller pattern by introducing a Custom Resource Definition (CRD). The operator watches ConfigWatcher custom resources that define relationships between ConfigMaps and workloads to restart.

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

- The operator watches ConfigWatcher custom resources instead of ConfigMap annotations
- Each ConfigWatcher defines a `configMap` name and `selector` for workloads to restart
- When a ConfigWatcher is created/modified, the operator restarts matching workloads
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

9. Trigger restart by changing ConfigMap

```bash
kubectl patch configmap webapp-config \
  --type merge -p '{"data":{"message":"Greets from your smooth operator!"}}'
```

- Watch operator logs; you should see it detect the ConfigWatcher and restart workloads
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
- Watches custom resources (ConfigWatcher)
- Separates configuration from behavior
- More declarative and Kubernetes-native
- Enables status reporting and lifecycle management
- Better for complex scenarios and multiple configurations
