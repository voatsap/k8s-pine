# Kubernetes Cluster Health Debugging

Quick commands for debugging cluster health issues based on Kubernetes official documentation.

## 🔍 Cluster Overview

### Basic Cluster Status
```bash
# Check all nodes
kubectl get nodes

# Check node details
kubectl get nodes -o wide

# Cluster info
kubectl cluster-info

# Detailed cluster dump
kubectl cluster-info dump
```

### Node Health
```bash
# Describe specific node
kubectl describe node NODE_NAME

# Get node YAML
kubectl get node NODE_NAME -o yaml

# Check node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

## 🏗️ Control Plane Health

### API Server
```bash
# Check API server health
kubectl get --raw='/healthz'

# API server readiness
kubectl get --raw='/readyz'

# API server version
kubectl version

# Check API server pods (if using kubeadm)
kubectl get pods -n kube-system | grep apiserver
```

### etcd Health
```bash
# Check etcd pods
kubectl get pods -n kube-system | grep etcd

# etcd member list (from etcd pod)
kubectl exec -n kube-system etcd-NODE_NAME -- etcdctl member list

# etcd cluster health
kubectl exec -n kube-system etcd-NODE_NAME -- etcdctl endpoint health --cluster
```

### Component Statuses
```bash
# Check component status (deprecated but useful)
kubectl get componentstatuses
```


## 🌐 Network Health

### Core Networking
```bash
# Check network plugin (CNI)
kubectl get pods -n kube-system | grep -E '(cilium|calico|flannel|weave)'

# Check DNS
kubectl get pods -n kube-system | grep dns

# Test DNS resolution
kubectl run test-dns --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default
```

## 📊 Resource Health

### Cluster Resources
```bash
# Node resource usage
kubectl top nodes

# Check resource quotas
kubectl get resourcequota --all-namespaces

# Check limit ranges
kubectl get limitrange --all-namespaces

# Check persistent volumes
kubectl get pv

# Check storage classes
kubectl get storageclass
```

## 🚨 Common Cluster Issues

### Scheduling Problems
```bash
# Check node taints
kubectl describe nodes | grep -A5 Taints

# Check resource availability
kubectl describe nodes | grep -A5 "Allocated resources"

# Check admission controllers
kubectl get --raw /api/v1 | grep admission
```

### Network Policies
```bash
# Check network policies
kubectl get networkpolicy --all-namespaces

# Check if network plugin supports policies
kubectl get pods -n kube-system | grep -E '(cilium|calico)'
```

## 🔍 Events & Logs

### Cluster Events
```bash
# All events sorted by time
kubectl get events --sort-by='.lastTimestamp' --all-namespaces

# Warning events only
kubectl get events --field-selector type=Warning --all-namespaces

# Events for specific namespace
kubectl get events -n NAMESPACE --sort-by='.lastTimestamp'
```


## ⚡ Quick Health Check Script

```bash
#!/bin/bash
echo "=== Cluster Health Check ==="
echo "Nodes:"
kubectl get nodes
echo
echo "System Pods:"
kubectl get pods -n kube-system | grep -v Running | grep -v Completed || echo "All system pods running"
echo
echo "Recent Events:"
kubectl get events --sort-by='.lastTimestamp' --all-namespaces | tail -10
echo
echo "Resource Usage:"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
```

## 🎯 Troubleshooting Checklist

```bash
# Essential cluster health checks
□ kubectl get nodes
□ kubectl cluster-info
□ kubectl get componentstatuses
□ kubectl get events --sort-by='.lastTimestamp' | tail -20
□ kubectl top nodes
□ kubectl get pv
□ kubectl get networkpolicy --all-namespaces
□ kubectl get --raw='/healthz'
□ kubectl get csr
```

## 🔧 Advanced Debugging

### Certificate Issues
```bash
# Check certificate signing requests
kubectl get csr

# Check service account tokens
kubectl get secrets --all-namespaces | grep token
```

### RBAC Issues
```bash
# Check cluster roles
kubectl get clusterroles

# Check role bindings
kubectl get rolebindings,clusterrolebindings --all-namespaces

# Test permissions
kubectl auth can-i VERB RESOURCE --as=USER
```

### Performance Issues
```bash
# API server error rates (focus on 4xx/5xx codes)
kubectl get --raw /metrics | grep "apiserver_request_total.*code=\"[45]"
# Look for: High counts of 403 (RBAC), 404 (missing resources), 500 (server errors)

# API server request latency summary (less verbose)
kubectl get --raw /metrics | grep "apiserver_request_duration_seconds_sum\|apiserver_request_duration_seconds_count" | head -10
# Look for: Calculate avg latency = sum/count. >0.1s for GET, >0.5s for POST/PUT/DELETE

# etcd backend latency summary
kubectl get --raw /metrics | grep "etcd_request_duration_seconds_sum\|etcd_request_duration_seconds_count" | head -5
# Look for: Calculate avg latency = sum/count. >0.01s indicates etcd issues

# Scheduler flow control (scheduler activity via API server)
kubectl get --raw /metrics | grep "apiserver_flowcontrol.*kube-scheduler" | grep "dispatched_requests_total\|current_inqueue"
# Look for: High inqueue values indicate scheduler bottlenecks

# Controller work queue status
kubectl get --raw /metrics | grep workqueue_depth | grep -v " 0$"
# Look for: Non-zero values indicate processing lag
kubectl get --raw /metrics | grep workqueue_adds_total | head -5
# Look for: Compare with processing rates to identify bottlenecks
```
