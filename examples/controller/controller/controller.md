# Controller Pattern: Simple ConfigMap Change Controller
 
 This example demonstrates a minimal Kubernetes controller implemented as a shell script running in a Deployment. It watches ConfigMaps for changes and restarts Pods whose labels match a selector provided as an annotation on the ConfigMap.
 
 ---
 
 ## Contents
 
 This guide now contains only description and usage. Manifests and the controller script are split into separate files under `examples/controller/`.
 
 See the Files section below and follow the Usage steps to deploy and test.
 
 ---
 
 ## Files
 
 - `examples/controller/controller/controller-rbac.yaml` — Namespace, ServiceAccount, ClusterRole, ClusterRoleBinding
 - `examples/controller/controller/controller-configmap.yaml` — ConfigMap embedding the controller script
 - `examples/controller/controller/controller-deployment.yaml` — Deployment mounting and running the script
 - `examples/controller/controller/sample-app.yaml` — Demo ConfigMap, Deployment, Service
 - `examples/controller/controller/controller.sh` — Script source (same logic as embedded in the ConfigMap for convenience)
 
 ---
 
 ## How it works
 
 - The controller watches for ConfigMap events and looks for the annotation `k8spatterns.io/restart-on-change`.
 - The annotation value is a Kubernetes label selector (e.g., `app=config-demo`).
 - On change, it attempts `kubectl rollout restart deploy -l <selector>`; if none, it deletes Pods matching the selector to force a restart.
 - The sample app serves the ConfigMap value as a web page.
 
 ---
 
 ## Usage Demo
 
 1. Apply controller RBAC, script (as ConfigMap), and Deployment
 
 ```bash
kubectl apply -f examples/controller/controller/controller-rbac.yaml
kubectl apply -f examples/controller/controller/controller-configmap.yaml
kubectl apply -f examples/controller/controller/controller-deployment.yaml
```
 
 2. Deploy the sample application
 
 ```bash
kubectl apply -f examples/controller/controller/sample-app.yaml
```
 
 3. Verify controller is running
 
 ```bash
kubectl get deploy,pods
kubectl logs deploy/configmap-restarter -f
```
 
 4. Access the app
 
 ```bash
kubectl port-forward svc/demo-app 8080:80
# Open http://localhost:8080 — should show: "Hello, students!"
```
 
 5. Trigger a restart by changing the ConfigMap
 
 ```bash
kubectl patch configmap demo-config \
  --type merge -p '{"data":{"message":"Hello, controllers!"}}'
 ```
 
 - Watch controller logs; you should see it detect the change and restart the Deployment or delete Pods.
 - Refresh http://localhost:8080 — content should update to: "Hello, controllers!"
 
 6. Cleanup
 
 ```bash
kubectl delete -f examples/controller/controller/sample-app.yaml
kubectl delete -f examples/controller/controller/controller-deployment.yaml
kubectl delete -f examples/controller/controller/controller-configmap.yaml
kubectl delete -f examples/controller/controller/controller-rbac.yaml
kubectl delete clusterrolebinding configmap-restarter --ignore-not-found
kubectl delete clusterrole configmap-restarter --ignore-not-found
 ```