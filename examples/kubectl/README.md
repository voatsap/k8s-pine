# Kubernetes kubectl Examples

This directory contains comprehensive examples of Kubernetes resources and kubectl commands based on the [Kubernetes Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/).

## 📁 Available Examples

### Core Workloads
- **`pod-random-generator.yaml`** - Pod with persistent volume
- **`deployment-nginx.yaml`** - Nginx deployment with 3 replicas
- **`replicaset-nginx.yaml`** - ReplicaSet managing nginx pods
- **`daemonset-nginx.yaml`** - DaemonSet running on all nodes
- **`statefulset-nginx.yaml`** - StatefulSet with persistent storage
- **`job-nginx.yaml`** - One-time job execution
- **`cronjob-nginx.yaml`** - Scheduled job execution

### Services & Networking
- **`service-nginx.yaml`** - ClusterIP service for nginx
- **`ingress-nginx.yaml`** - Ingress for external access

### Configuration & Storage
- **`configmap-nginx.yaml`** - Configuration data
- **`secret-nginx.yaml`** - Sensitive data storage
- **`pvc-random-generator.yaml`** - Persistent Volume Claim
- **`namespace.yaml`** - Namespace with ResourceQuota

### RBAC (Role-Based Access Control)
- **`role-pod-reader.yaml`** - Role for reading pods and logs
- **`rolebinding-pod-reader.yaml`** - Bind pod-reader role to users/ServiceAccounts
- **`role-deployment-manager.yaml`** - Role for managing deployments
- **`rolebinding-deployment-manager.yaml`** - Bind deployment-manager role
- **`clusterrole-node-reader.yaml`** - ClusterRole for reading nodes
- **`clusterrolebinding-node-reader.yaml`** - Bind node-reader ClusterRole
- **`clusterrole-namespace-admin.yaml`** - ClusterRole for namespace administration
- **`clusterrolebinding-namespace-admin.yaml`** - Bind namespace-admin ClusterRole
- **`serviceaccount-examples.yaml`** - ServiceAccounts for RBAC testing
- **`pod-with-serviceaccount.yaml`** - Pod using ServiceAccount for RBAC testing

## 🚀 Quick Start Commands

### Apply Resources
```bash
# Apply all examples
k apply -f examples/kubectl/

# Apply specific resource
k apply -f examples/kubectl/deployment-nginx.yaml

# Apply with namespace
k apply -f examples/kubectl/namespace.yaml
k apply -f examples/kubectl/deployment-nginx.yaml -n nginx-namespace
```

### Basic kubectl Commands

#### Creating Resources
```bash
# Create from file
k create -f deployment-nginx.yaml

# Create namespace
k create namespace my-namespace

# Create deployment imperatively
k create deployment nginx --image=nginx:1.25 --replicas=3

# Create service
k create service clusterip nginx --tcp=80:80

# Create configmap from literal
k create configmap app-config --from-literal=key1=value1

# Create secret
k create secret generic app-secret --from-literal=password=secret123
```

#### Viewing Resources
```bash
# Get all resources
k get all

# Get specific resources
k get pods
k get deployments
k get services
k get ingress

# Get with wide output
k get pods -o wide

# Get with custom columns
k get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Get in different formats
k get pods -o yaml
k get pods -o json
k get pods -o jsonpath='{.items[*].metadata.name}'

# Watch resources
k get pods --watch
k get pods -w

# Get from all namespaces
k get pods --all-namespaces
k get pods -A
```

#### Describing Resources
```bash
# Describe pod
k describe pod nginx-deployment-xxx

# Describe deployment
k describe deployment nginx-deployment

# Describe service
k describe service nginx-service

# Describe node
k describe node worker-node-1
```

#### Editing Resources
```bash
# Edit deployment
k edit deployment nginx-deployment

# Edit service
k edit service nginx-service

# Scale deployment
k scale deployment nginx-deployment --replicas=5

# Patch resource
k patch deployment nginx-deployment -p '{"spec":{"replicas":2}}'
```

#### Logs and Debugging
```bash
# Get pod logs
k logs nginx-deployment-xxx

# Follow logs
k logs -f nginx-deployment-xxx

# Get logs from previous container
k logs nginx-deployment-xxx --previous

# Get logs from all containers in pod
k logs nginx-deployment-xxx --all-containers

# Execute commands in pod
k exec -it nginx-deployment-xxx -- /bin/bash
k exec -it nginx-deployment-xxx -- nginx -t

# Port forwarding
k port-forward pod/nginx-deployment-xxx 8080:80
k port-forward service/nginx-service 8080:80

# Copy files
k cp nginx-deployment-xxx:/etc/nginx/nginx.conf ./nginx.conf
k cp ./index.html nginx-deployment-xxx:/usr/share/nginx/html/
```

#### Resource Management
```bash
# Delete resources
k delete pod nginx-deployment-xxx
k delete deployment nginx-deployment
k delete -f deployment-nginx.yaml

# Delete all resources of a type
k delete pods --all
k delete deployments --all

# Force delete
k delete pod nginx-deployment-xxx --force --grace-period=0

# Drain node
k drain worker-node-1 --ignore-daemonsets

# Cordon/Uncordon node
k cordon worker-node-1
k uncordon worker-node-1
```

## 🔍 Advanced kubectl Commands

### Resource Information
```bash
# Get API resources
k api-resources
k api-resources --namespaced=true
k api-resources --namespaced=false

# Get API versions
k api-versions

# Explain resource fields
k explain pod
k explain pod.spec
k explain deployment.spec.template.spec.containers

# Get cluster info
k cluster-info
k cluster-info dump
```

### Context and Configuration
```bash
# View current context
k config current-context

# List contexts
k config get-contexts

# Switch context
k config use-context my-context

# Set namespace for context
k config set-context --current --namespace=my-namespace

# View kubeconfig
k config view
k config view --minify
```

### Labels and Selectors
```bash
# Get pods with labels
k get pods --show-labels

# Filter by labels
k get pods -l app=nginx
k get pods -l 'app in (nginx,apache)'
k get pods -l app=nginx,version=1.0

# Add label
k label pod nginx-xxx environment=production

# Remove label
k label pod nginx-xxx environment-

# Label nodes
k label node worker-1 disktype=ssd
```

### Resource Usage and Metrics
```bash
# Get resource usage
k top nodes
k top pods
k top pods --containers

# Get events
k get events
k get events --sort-by=.metadata.creationTimestamp

# Get resource quotas
k get resourcequota
k describe resourcequota
```

### Rollouts and Updates
```bash
# Check rollout status
k rollout status deployment/nginx-deployment

# View rollout history
k rollout history deployment/nginx-deployment

# Rollback deployment
k rollout undo deployment/nginx-deployment
k rollout undo deployment/nginx-deployment --to-revision=2

# Restart deployment
k rollout restart deployment/nginx-deployment

# Pause/Resume rollout
k rollout pause deployment/nginx-deployment
k rollout resume deployment/nginx-deployment
```

## 🎯 Practical Examples

### Example 1: Deploy and Expose Nginx
```bash
# Create namespace
k create namespace nginx-demo

# Deploy nginx
k apply -f deployment-nginx.yaml -n nginx-demo

# Expose as service
k apply -f service-nginx.yaml -n nginx-demo

# Check status
k get all -n nginx-demo

# Test connectivity
k port-forward service/nginx-service 8080:80 -n nginx-demo
# Visit http://localhost:8080
```

### Example 2: Debug Pod Issues
```bash
# Get pod status
k get pods -o wide

# Check pod details
k describe pod nginx-deployment-xxx

# Check logs
k logs nginx-deployment-xxx

# Execute into pod
k exec -it nginx-deployment-xxx -- /bin/bash

# Check events
k get events --field-selector involvedObject.name=nginx-deployment-xxx
```

### Example 3: Scale and Update Application
```bash
# Scale deployment
k scale deployment nginx-deployment --replicas=5

# Update image
k set image deployment/nginx-deployment nginx=nginx:1.26

# Check rollout
k rollout status deployment/nginx-deployment

# View history
k rollout history deployment/nginx-deployment
```

## 📈 Deployment Scaling Examples

The nginx deployment includes rolling update strategy with:
- **maxSurge: 1** - Allow 1 extra pod during updates
- **maxUnavailable: 1** - Allow 1 pod to be unavailable during updates

### Manual Scaling Commands

```bash
# Scale up to 5 replicas
k scale deployment nginx-deployment --replicas=5

# Scale down to 2 replicas
k scale deployment nginx-deployment --replicas=2

# Scale with timeout
k scale deployment nginx-deployment --replicas=10 --timeout=60s

# Check current replica count
k get deployment nginx-deployment -o jsonpath='{.spec.replicas}'

# Watch scaling in real-time
k get pods -w -l app=nginx
```

### Horizontal Pod Autoscaler (HPA)

```bash
# Create HPA based on CPU usage (requires metrics-server)
k autoscale deployment nginx-deployment --cpu-percent=70 --min=2 --max=10

# Create HPA with memory and CPU metrics
k apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

# Check HPA status
k get hpa
k describe hpa nginx-hpa

# Delete HPA
k delete hpa nginx-hpa
```

### Rolling Update Strategy Examples

```bash
# Update deployment with new image (triggers rolling update)
k set image deployment/nginx-deployment nginx=nginx:1.26

# Update with different rolling update settings
k patch deployment nginx-deployment -p '{
  "spec": {
    "strategy": {
      "rollingUpdate": {
        "maxSurge": "50%",
        "maxUnavailable": "25%"
      }
    }
  }
}'

# Monitor rolling update progress
k rollout status deployment/nginx-deployment --watch=true

# Pause rollout (useful if issues detected)
k rollout pause deployment/nginx-deployment

# Resume rollout
k rollout resume deployment/nginx-deployment

# Rollback to previous version
k rollout undo deployment/nginx-deployment

# Rollback to specific revision
k rollout history deployment/nginx-deployment
k rollout undo deployment/nginx-deployment --to-revision=2
```

### Load Testing for Scaling

```bash
# Generate load to test autoscaling (requires HPA)
k run load-generator --image=busybox --restart=Never -- /bin/sh -c "
  while true; do
    wget -q -O- http://nginx-service.default.svc.cluster.local/
    sleep 0.01
  done
"

# Monitor HPA during load test
k get hpa nginx-hpa --watch

# Clean up load generator
k delete pod load-generator
```

### Scaling Best Practices

```bash
# Check resource requests/limits before scaling
k describe deployment nginx-deployment | grep -A 10 "Limits\|Requests"

# Monitor resource usage during scaling
k top pods -l app=nginx

# Check node capacity before large scale operations
k describe nodes | grep -A 5 "Allocated resources"

# Scale gradually for production workloads
k scale deployment nginx-deployment --replicas=6
# Wait and monitor...
k scale deployment nginx-deployment --replicas=8
# Wait and monitor...
k scale deployment nginx-deployment --replicas=10
```

## 🔐 RBAC (Role-Based Access Control) Examples

### Understanding RBAC Components

**RBAC consists of four main components:**
- **Role/ClusterRole** - Defines permissions (what can be done)
- **RoleBinding/ClusterRoleBinding** - Grants permissions (who can do it)
- **ServiceAccount** - Identity for pods/applications
- **User/Group** - Identity for human users

### RBAC Resource Hierarchy

```
Namespace-Scoped:          Cluster-Scoped:
├── Role                   ├── ClusterRole
├── RoleBinding            ├── ClusterRoleBinding
└── ServiceAccount        └── Node, PV, StorageClass, etc.
```

### Apply RBAC Examples

```bash
# Apply all RBAC resources
k apply -f serviceaccount-examples.yaml
k apply -f role-pod-reader.yaml
k apply -f rolebinding-pod-reader.yaml
k apply -f role-deployment-manager.yaml
k apply -f rolebinding-deployment-manager.yaml
k apply -f clusterrole-node-reader.yaml
k apply -f clusterrolebinding-node-reader.yaml
k apply -f clusterrole-namespace-admin.yaml
k apply -f clusterrolebinding-namespace-admin.yaml

# Deploy test pod with ServiceAccount
k apply -f pod-with-serviceaccount.yaml
```

### Testing RBAC Permissions

#### 1. Test ServiceAccount Permissions in Pod

```bash
# Exec into the RBAC test pod
k exec -it rbac-test-pod -- /bin/bash

# Inside the pod, test permissions:
# ✅ Should work (pod-reader role allows this)
kubectl get pods
kubectl get pods nginx-statefulset-0 -o yaml
kubectl logs nginx-statefulset-0

# ❌ Should fail (pod-reader role doesn't allow this)
kubectl delete pod nginx-statefulset-0
kubectl create deployment test --image=nginx
kubectl get nodes

# Exit the pod
exit
```

#### 2. Check Role Permissions

```bash
# View role permissions
k describe role pod-reader
k describe role deployment-manager

# View ClusterRole permissions
k describe clusterrole node-reader
k describe clusterrole namespace-admin

# Check what a ServiceAccount can do
k auth can-i get pods --as=system:serviceaccount:default:pod-reader-sa
k auth can-i delete pods --as=system:serviceaccount:default:pod-reader-sa
k auth can-i create deployments --as=system:serviceaccount:default:deployment-manager-sa
```

#### 3. Test User Permissions (Simulated)

```bash
# Check permissions for different users
k auth can-i get pods --as=developer
k auth can-i delete deployments --as=devops-user
k auth can-i get nodes --as=monitoring-user
k auth can-i create namespaces --as=platform-admin

# List all permissions for a user
k auth can-i --list --as=developer
k auth can-i --list --as=system:serviceaccount:default:pod-reader-sa
```

#### 4. View RBAC Bindings

```bash
# View RoleBindings
k get rolebindings
k describe rolebinding read-pods

# View ClusterRoleBindings
k get clusterrolebindings
k describe clusterrolebinding read-nodes

# Find all bindings for a specific user/ServiceAccount
k get rolebindings,clusterrolebindings -o wide | grep pod-reader-sa
```

### RBAC Troubleshooting

```bash
# Check if RBAC is enabled
k api-versions | grep rbac

# View current user context
k config current-context
k config view --minify

# Debug permission issues
k auth can-i create pods --v=6
k auth can-i get nodes --as=system:serviceaccount:default:pod-reader-sa --v=6

# View ServiceAccount token and permissions
k get serviceaccount pod-reader-sa -o yaml
k describe secret $(k get serviceaccount pod-reader-sa -o jsonpath='{.secrets[0].name}')
```

### Common RBAC Patterns

#### Pattern 1: Read-Only Access
```bash
# Create a read-only role for specific resources
k create role readonly --verb=get,list,watch --resource=pods,services,configmaps
k create rolebinding readonly-binding --role=readonly --user=readonly-user
```

#### Pattern 2: Namespace Admin
```bash
# Grant admin access to a specific namespace
k create rolebinding admin-binding --clusterrole=admin --user=namespace-admin --namespace=production
```

#### Pattern 3: Cross-Namespace Access
```bash
# Use ClusterRole with RoleBinding for cross-namespace access
k create rolebinding cross-ns-access --clusterrole=view --user=developer --namespace=staging
```

#### Pattern 4: Service Account for Applications
```bash
# Create ServiceAccount for application
k create serviceaccount app-sa
k create role app-role --verb=get,list --resource=configmaps,secrets
k create rolebinding app-binding --role=app-role --serviceaccount=default:app-sa

# Use in deployment
kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"serviceAccountName":"app-sa"}}}}'
```

### RBAC Security Best Practices

```bash
# 1. Principle of Least Privilege - Grant minimal required permissions
k create role minimal-role --verb=get --resource=pods --resource-name=specific-pod

# 2. Use specific resource names when possible
k create role specific-access --verb=get,update --resource=configmaps --resource-name=app-config

# 3. Avoid using wildcards in production
# ❌ Bad: --verb=* --resource=*
# ✅ Good: --verb=get,list,watch --resource=pods,services

# 4. Regular audit of permissions
k get rolebindings,clusterrolebindings -o wide
k auth can-i --list --as=system:serviceaccount:default:suspicious-sa

# 5. Use groups for user management
k create clusterrolebinding developers --clusterrole=view --group=developers
```

### Cleanup RBAC Resources

```bash
# Delete RBAC test resources
k delete -f pod-with-serviceaccount.yaml
k delete -f serviceaccount-examples.yaml
k delete -f role-pod-reader.yaml
k delete -f rolebinding-pod-reader.yaml
k delete -f role-deployment-manager.yaml
k delete -f rolebinding-deployment-manager.yaml
k delete -f clusterrole-node-reader.yaml
k delete -f clusterrolebinding-node-reader.yaml
k delete -f clusterrole-namespace-admin.yaml
k delete -f clusterrolebinding-namespace-admin.yaml
```

### Example 4: Working with ConfigMaps and Secrets
```bash
# Create configmap
k apply -f configmap-nginx.yaml

# Create secret
k apply -f secret-nginx.yaml

# View configmap data
k get configmap nginx-config -o yaml

# View secret (base64 encoded)
k get secret nginx-secret -o yaml

# Decode secret
k get secret nginx-secret -o jsonpath='{.data.password}' | base64 -d
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

## 🎓 Learning Path

1. **Start with basic resources**: Pod, Deployment, Service
2. **Learn resource management**: Create, get, describe, delete
3. **Practice debugging**: Logs, exec, port-forward
4. **Explore advanced features**: Labels, selectors, rollouts
5. **Work with configuration**: ConfigMaps, Secrets, PVCs
6. **Master networking**: Services, Ingress, NetworkPolicies

## 💡 Tips

- Use `k explain <resource>` to understand resource fields
- Always check `k get events` when troubleshooting
- Use `--dry-run=client -o yaml` to generate YAML templates
- Combine `watch` with kubectl commands: `watch kubectl get pods`
- Use `stern` for advanced log tailing across multiple pods
- Practice with `k9s` for interactive cluster management
