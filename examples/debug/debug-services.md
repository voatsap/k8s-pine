# Kubernetes Service Debugging Guide (Cilium CNI)

Comprehensive guide for debugging Kubernetes service issues in clusters using Cilium CNI instead of traditional kube-proxy.

## 🔍 Service Debugging Overview

Service debugging follows a systematic approach:
1. **Verify Service Definition** - Check service exists and is configured correctly
2. **Check Endpoints** - Ensure pods are selected and healthy
3. **Test DNS Resolution** - Verify service discovery works
4. **Debug Network Connectivity** - Test direct pod-to-pod and service communication
5. **Investigate Cilium** - Check CNI-specific networking components

## 📋 Basic Service Diagnostics

### Quick Service Check
```bash
# List all services
kubectl get services --all-namespaces

# Check specific service
kubectl get service SERVICE_NAME

# Detailed service information
kubectl describe service SERVICE_NAME

# Check service endpoints
kubectl get endpoints SERVICE_NAME
kubectl get endpointslices -l kubernetes.io/service-name=SERVICE_NAME
```

### Service Status Analysis
```bash
# Services without endpoints
kubectl get services --all-namespaces -o wide | grep '<none>'

# Check service selectors vs pod labels
kubectl get service SERVICE_NAME -o yaml | grep -A 5 selector
kubectl get pods -l LABEL_KEY=LABEL_VALUE

# Service port configuration
kubectl get service SERVICE_NAME -o jsonpath='{.spec.ports[*]}'
```

## 🚨 Common Service Issues & Examples

### 1. Service with No Endpoints

**Example:** `samples/service-no-endpoints.yaml`

**Issue:** Service selector doesn't match pod labels

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/service-no-endpoints.yaml

# Check service (will show no endpoints)
kubectl get service service-no-endpoints
kubectl describe service service-no-endpoints

# Check endpoints
kubectl get endpoints service-no-endpoints

# Compare selectors and labels
kubectl get service service-no-endpoints -o jsonpath='{.spec.selector}'
kubectl get pods -l app=web-app --show-labels

# Fix by updating service selector
kubectl patch service service-no-endpoints -p '{"spec":{"selector":{"app":"web-app"}}}'
```

### 2. Wrong Target Port

**Example:** `samples/service-wrong-port.yaml`

**Issue:** Service targetPort doesn't match container port

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/service-wrong-port.yaml

# Check service configuration
kubectl describe service service-wrong-port

# Check pod ports
kubectl get pods -l app=web-app -o jsonpath='{.items[*].spec.containers[*].ports[*].containerPort}'

# Test direct pod access
kubectl run debug-pod --rm -it --image=busybox --restart=Never -- sh
# Inside pod: wget -qO- POD_IP:80  # This works
# Inside pod: wget -qO- SERVICE_IP:80  # This fails

# Fix by updating target port
kubectl patch service service-wrong-port -p '{"spec":{"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'
```

### 3. DNS Resolution Issues

**Example:** `samples/service-dns-issue.yaml`

**Issue:** Cross-namespace service access or DNS problems

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/service-dns-issue.yaml

# Test DNS resolution from default namespace
kubectl run debug-pod --rm -it --image=busybox --restart=Never -- sh
# Inside pod: nslookup service-dns-issue  # Fails - wrong namespace
# Inside pod: nslookup service-dns-issue.test-namespace.svc.cluster.local  # Works

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test DNS from same namespace
kubectl run debug-pod -n test-namespace --rm -it --image=busybox --restart=Never -- sh
# Inside pod: nslookup service-dns-issue  # Works
```

## 🔧 Cilium-Specific Debugging

### Cilium Status Check
```bash
# Check Cilium pods
kubectl get pods -n kube-system -l k8s-app=cilium

# Cilium status
kubectl exec -n kube-system cilium-XXXXX -- cilium status

# Cilium connectivity test
kubectl exec -n kube-system cilium-XXXXX -- cilium connectivity test

# Check Cilium service list
kubectl exec -n kube-system cilium-XXXXX -- cilium service list
```

### Cilium Network Policy
```bash
# Check network policies affecting service
kubectl get networkpolicies --all-namespaces

# Cilium endpoint status
kubectl exec -n kube-system cilium-XXXXX -- cilium endpoint list

# Check service load balancing
kubectl exec -n kube-system cilium-XXXXX -- cilium bpf lb list
```

### Cilium Service Debugging
```bash
# Check Cilium service mapping
kubectl exec -n kube-system cilium-XXXXX -- cilium service get SERVICE_ID

# Monitor Cilium events
kubectl exec -n kube-system cilium-XXXXX -- cilium monitor --type=drop

# Check eBPF maps
kubectl exec -n kube-system cilium-XXXXX -- cilium bpf service list
```

## 🔍 Advanced Service Debugging

### Network Connectivity Testing
```bash
# Create debug pod for testing
kubectl run debug-pod --image=nicolaka/netshoot --rm -it --restart=Never -- bash

# Inside debug pod:
# Test service by IP
curl SERVICE_IP:PORT

# Test service by DNS
curl SERVICE_NAME:PORT
curl SERVICE_NAME.NAMESPACE.svc.cluster.local:PORT

# Test direct pod access
curl POD_IP:PORT

# Check routing
ip route
netstat -tuln
ss -tuln
```

### Service Discovery Testing
```bash
# DNS resolution test
kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh
# Inside pod:
nslookup SERVICE_NAME
nslookup SERVICE_NAME.NAMESPACE.svc.cluster.local
nslookup kubernetes.default.svc.cluster.local

# Check DNS configuration
cat /etc/resolv.conf
```

### Pod-to-Pod Communication
```bash
# Get pod IPs
kubectl get pods -o wide

# Test direct pod communication
kubectl exec POD_NAME -- wget -qO- POD_IP:PORT

# Test service communication
kubectl exec POD_NAME -- wget -qO- SERVICE_NAME:PORT
```

## 🎯 Cilium Troubleshooting Workflows

### Service Connectivity Workflow
```bash
#!/bin/bash
SERVICE_NAME=$1
NAMESPACE=${2:-default}

echo "=== Service Connectivity Debug Workflow ==="
echo "Service: $SERVICE_NAME in namespace: $NAMESPACE"
echo

echo "1. Service Status:"
kubectl get service $SERVICE_NAME -n $NAMESPACE

echo "2. Service Endpoints:"
kubectl get endpoints $SERVICE_NAME -n $NAMESPACE

echo "3. EndpointSlices:"
kubectl get endpointslices -n $NAMESPACE -l kubernetes.io/service-name=$SERVICE_NAME

echo "4. Pod Status:"
SELECTOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector}' | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")')
kubectl get pods -n $NAMESPACE -l "$SELECTOR"

echo "5. Cilium Service Status:"
CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system $CILIUM_POD -- cilium service list | grep $SERVICE_NAME
```

### Cilium Network Debug
```bash
#!/bin/bash
POD_NAME=$1
NAMESPACE=${2:-default}

echo "=== Cilium Network Debug ==="
echo "Pod: $POD_NAME in namespace: $NAMESPACE"
echo

echo "1. Pod Network Info:"
kubectl get pod $POD_NAME -n $NAMESPACE -o wide

echo "2. Cilium Endpoint:"
POD_IP=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.status.podIP}')
CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system $CILIUM_POD -- cilium endpoint list | grep $POD_IP

echo "3. Network Policies:"
kubectl get networkpolicies -n $NAMESPACE

echo "4. Cilium Connectivity:"
kubectl exec -n kube-system $CILIUM_POD -- cilium endpoint get $(kubectl exec -n kube-system $CILIUM_POD -- cilium endpoint list | grep $POD_IP | awk '{print $1}')
```

## 📊 Service Performance Analysis

### Service Latency Testing
```bash
# Create performance test pod
kubectl run perf-test --image=busybox --rm -it --restart=Never -- sh

# Inside pod - test service response time
time wget -qO- SERVICE_NAME:PORT

# Multiple requests test
for i in {1..10}; do
  time wget -qO- SERVICE_NAME:PORT >/dev/null 2>&1
done
```

### Load Balancing Verification
```bash
# Test service load balancing
kubectl run lb-test --image=busybox --rm -it --restart=Never -- sh

# Inside pod - multiple requests to see different backends
for i in {1..20}; do
  wget -qO- SERVICE_NAME:PORT
done
```

### Cilium Load Balancer Stats
```bash
# Check Cilium load balancer statistics
CILIUM_POD=$(kubectl get pods -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system $CILIUM_POD -- cilium bpf lb list

# Monitor service traffic
kubectl exec -n kube-system $CILIUM_POD -- cilium monitor --type=l7
```

## 🔧 Common Fixes

### Update Service Selector
```bash
# Fix mismatched selectors
kubectl patch service SERVICE_NAME -p '{"spec":{"selector":{"app":"correct-label"}}}'
```

### Fix Port Configuration
```bash
# Update target port
kubectl patch service SERVICE_NAME -p '{"spec":{"ports":[{"port":80,"targetPort":8080,"protocol":"TCP"}]}}'
```

### Restart Cilium (if needed)
```bash
# Restart Cilium pods
kubectl delete pods -n kube-system -l k8s-app=cilium

# Wait for restart
kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=cilium --timeout=300s
```

## 🎯 Quick Debug Checklist

```bash
# Essential service debugging steps
□ kubectl get service SERVICE_NAME
□ kubectl describe service SERVICE_NAME
□ kubectl get endpoints SERVICE_NAME
□ kubectl get pods -l SELECTOR_LABELS
□ kubectl exec -n kube-system cilium-XXX -- cilium service list
□ kubectl run debug-pod --image=busybox --rm -it -- nslookup SERVICE_NAME
□ kubectl run debug-pod --image=busybox --rm -it -- wget -qO- SERVICE_NAME:PORT
□ kubectl get networkpolicies --all-namespaces
```

## 🧹 Cleanup Commands

```bash
# Delete example services and deployments
kubectl delete -f samples/service-no-endpoints.yaml
kubectl delete -f samples/service-wrong-port.yaml
kubectl delete -f samples/service-dns-issue.yaml

# Clean up debug pods
kubectl delete pod debug-pod --ignore-not-found
kubectl delete pod perf-test --ignore-not-found
kubectl delete pod lb-test --ignore-not-found

# Remove test namespace
kubectl delete namespace test-namespace --ignore-not-found
```

