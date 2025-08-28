# Kubernetes Pod Debugging Guide

Comprehensive guide for debugging pod issues with practical examples and commands based on official Kubernetes documentation.

## 🔍 Pod Debugging Overview

Pod debugging follows a systematic approach:
1. **Diagnose** - Check pod status and events
2. **Analyze** - Examine logs and resource usage
3. **Debug** - Use exec, ephemeral containers, or copies
4. **Fix** - Apply corrections based on findings

## 📋 Basic Pod Diagnostics

### Quick Status Check
```bash
# Check pod status
kubectl get pods

# Detailed pod information
kubectl describe pod POD_NAME

# Check events for the pod
kubectl get events --field-selector involvedObject.name=POD_NAME

# Check pod resource usage
kubectl top pod POD_NAME
```

### Pod State Analysis
```bash
# Check all pods with issues
kubectl get pods --all-namespaces | grep -v Running

# Pending pods
kubectl get pods --field-selector=status.phase=Pending

# Failed pods
kubectl get pods --field-selector=status.phase=Failed

# Pods with restarts
kubectl get pods --all-namespaces -o wide | awk '$5 > 0 {print}'
```

## 🚨 Common Pod Issues & Examples

### 1. CrashLoopBackOff

**Example Pod:** `samples/crashloop-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/crashloop-pod.yaml

# Check status (will show CrashLoopBackOff)
kubectl get pod crashloop-example

# Get detailed information
kubectl describe pod crashloop-example

# Check current logs
kubectl logs crashloop-example

# Check previous container logs
kubectl logs crashloop-example --previous

# Check restart count and reason
kubectl get pod crashloop-example -o jsonpath='{.status.containerStatuses[0].restartCount}'
kubectl get pod crashloop-example -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

### 2. Out of Memory (OOMKilled)

**Example Pod:** `samples/oom-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/oom-pod.yaml

# Check status (will show OOMKilled)
kubectl describe pod oom-example

# Check termination reason
kubectl get pod oom-example -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# Check memory limits vs requests
kubectl describe pod oom-example | grep -A 10 "Limits\|Requests"

# Monitor resource usage (if pod is running)
kubectl top pod oom-example
```

### 3. Pending Pods

**Example Pod:** `samples/pending-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/pending-pod.yaml

# Check status (will show Pending)
kubectl get pod pending-example

# Check scheduling events
kubectl describe pod pending-example

# Check node resources
kubectl describe nodes

# Check available resources
kubectl top nodes

# Check if pod has node selector or tolerations
kubectl get pod pending-example -o yaml | grep -A 10 "nodeSelector\|tolerations"
```

### 4. ImagePullBackOff

**Example Pod:** `samples/image-pull-error-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/image-pull-error-pod.yaml

# Check status (will show ImagePullBackOff)
kubectl get pod image-pull-error-example

# Check pull events
kubectl describe pod image-pull-error-example

# Check image name
kubectl get pod image-pull-error-example -o jsonpath='{.spec.containers[0].image}'

# Test image pull manually (from node)
kubectl debug node/NODE_NAME -it --image=ubuntu --profile=sysadmin -- chroot /host docker pull nonexistent/fake-image:latest
```

### 5. Terminating Pods

**Example Pod:** `samples/terminating-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/terminating-pod.yaml

# Try to delete (will get stuck)
kubectl delete pod terminating-example

# Check status (will show Terminating)
kubectl get pod terminating-example

# Check finalizers
kubectl get pod terminating-example -o jsonpath='{.metadata.finalizers}'

# Remove finalizers to allow deletion
kubectl patch pod terminating-example -p '{"metadata":{"finalizers":null}}'

# Force delete (if needed)
kubectl delete pod terminating-example --force --grace-period=0

# Check for admission webhooks
kubectl get validatingwebhookconfiguration
kubectl get mutatingwebhookconfiguration
```

### 6. HostPort Conflicts

**Example Pod:** `samples/hostport-pod.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/hostport-pod.yaml

# Try to create a second pod with same hostPort (will fail)
kubectl apply -f samples/hostport-pod.yaml

# Check scheduling events
kubectl describe pod hostport-example

# Check port usage on nodes
kubectl debug node/NODE_NAME -it --image=ubuntu --profile=sysadmin -- chroot /host netstat -tuln | grep 8080
```

## 🔧 Advanced Debugging Techniques

### Container Logs Analysis
```bash
# Current logs
kubectl logs POD_NAME -c CONTAINER_NAME

# Previous container logs (after crash)
kubectl logs POD_NAME -c CONTAINER_NAME --previous

# Follow logs in real-time
kubectl logs POD_NAME -c CONTAINER_NAME -f

# Logs with timestamps
kubectl logs POD_NAME -c CONTAINER_NAME --timestamps

# Last N lines
kubectl logs POD_NAME -c CONTAINER_NAME --tail=50

# Logs since specific time
kubectl logs POD_NAME -c CONTAINER_NAME --since=1h
```

### Container Exec Debugging
```bash
# Execute command in container
kubectl exec POD_NAME -c CONTAINER_NAME -- COMMAND

# Interactive shell
kubectl exec -it POD_NAME -c CONTAINER_NAME -- /bin/bash

# Check processes
kubectl exec POD_NAME -c CONTAINER_NAME -- ps aux

# Check filesystem
kubectl exec POD_NAME -c CONTAINER_NAME -- df -h

# Check network
kubectl exec POD_NAME -c CONTAINER_NAME -- netstat -tuln

# Check environment variables
kubectl exec POD_NAME -c CONTAINER_NAME -- env
```

### Ephemeral Debug Containers
```bash
# Add debug container to running pod
kubectl debug POD_NAME -it --image=busybox --target=CONTAINER_NAME

# Debug with network tools
kubectl debug POD_NAME -it --image=nicolaka/netshoot

# Debug with system tools
kubectl debug POD_NAME -it --image=ubuntu --share-processes --copy-to=POD_NAME-debug
```

### Pod Copy Debugging
```bash
# Copy pod with different command
kubectl debug POD_NAME -it --copy-to=POD_NAME-debug --container=CONTAINER_NAME -- sh

# Copy pod with different image
kubectl debug POD_NAME -it --copy-to=POD_NAME-debug --set-image=CONTAINER_NAME=busybox

# Copy pod and add debug container
kubectl debug POD_NAME -it --copy-to=POD_NAME-debug --image=busybox
```

## 📊 Resource Analysis

### Memory Issues
```bash
# Check memory usage
kubectl top pod POD_NAME --containers

# Check memory limits and requests
kubectl describe pod POD_NAME | grep -A 5 "Limits\|Requests"

# Check OOM events
kubectl get events | grep OOMKilling

# Memory pressure on nodes
kubectl describe nodes | grep MemoryPressure
```

### CPU Issues
```bash
# Check CPU usage
kubectl top pod POD_NAME --containers

# Check CPU throttling
kubectl describe pod POD_NAME | grep -i cpu

# Check CPU limits
kubectl get pod POD_NAME -o jsonpath='{.spec.containers[*].resources}'
```

### Storage Issues
```bash
# Check volume mounts
kubectl describe pod POD_NAME | grep -A 10 Mounts

# Check persistent volumes
kubectl get pv,pvc

# Check storage class
kubectl get storageclass

# Check disk usage in container
kubectl exec POD_NAME -- df -h
```

## 🎯 Troubleshooting Workflows

### CrashLoopBackOff Workflow
```bash
#!/bin/bash
POD_NAME=$1

echo "=== CrashLoopBackOff Debug Workflow ==="
echo "Pod: $POD_NAME"
echo

echo "1. Current Status:"
kubectl get pod $POD_NAME

echo "2. Restart Count:"
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[0].restartCount}'

echo "3. Exit Code:"
kubectl get pod $POD_NAME -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

echo "4. Recent Events:"
kubectl get events --field-selector involvedObject.name=$POD_NAME --sort-by='.lastTimestamp' | tail -5

echo "5. Current Logs:"
kubectl logs $POD_NAME --tail=20

echo "6. Previous Logs:"
kubectl logs $POD_NAME --previous --tail=20
```

### Resource Investigation
```bash
#!/bin/bash
POD_NAME=$1

echo "=== Resource Investigation ==="
echo "Pod: $POD_NAME"
echo

echo "1. Resource Requests/Limits:"
kubectl describe pod $POD_NAME | grep -A 10 "Requests\|Limits"

echo "2. Current Usage:"
kubectl top pod $POD_NAME --containers

echo "3. Node Resources:"
NODE=$(kubectl get pod $POD_NAME -o jsonpath='{.spec.nodeName}')
kubectl describe node $NODE | grep -A 5 "Allocated resources"

echo "4. Memory/CPU Events:"
kubectl get events | grep -E "(MemoryPressure|DiskPressure|OutOf|Failed.*resource)"
```

## 🎯 Quick Debug Checklist

```bash
# Essential pod debugging steps
□ kubectl get pod POD_NAME
□ kubectl describe pod POD_NAME
□ kubectl logs POD_NAME
□ kubectl logs POD_NAME --previous
□ kubectl get events --field-selector involvedObject.name=POD_NAME
□ kubectl top pod POD_NAME
□ kubectl get pod POD_NAME -o yaml
□ kubectl exec -it POD_NAME -- sh (if running)
```

## 🔄 Init Container Debugging

Init containers run before the main application containers and must complete successfully before the main containers start. Common issues include failures, slow execution, and image pull problems.

### 1. Failing Init Container

**Example Pod:** `samples/init-container-failing.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/init-container-failing.yaml

# Check status (will show Init:1/2 - first init succeeded, second failed)
kubectl get pod init-container-failing

# Get detailed information about init containers
kubectl describe pod init-container-failing

# Check init container logs
kubectl logs init-container-failing -c init-setup
kubectl logs init-container-failing -c init-failing

# Check init container status programmatically
kubectl get pod init-container-failing -o jsonpath='{.status.initContainerStatuses[*].state}'

# Check which init container failed
kubectl get pod init-container-failing -o jsonpath='{.status.initContainerStatuses[*].name}'
kubectl get pod init-container-failing -o jsonpath='{.status.initContainerStatuses[*].lastState.terminated.exitCode}'
```

### 2. Slow Init Container

**Example Pod:** `samples/init-container-slow.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/init-container-slow.yaml

# Check status (will show Init:0/2, then Init:1/2, then PodInitializing)
kubectl get pod init-container-slow

# Watch the progress
kubectl get pod init-container-slow -w

# Check logs of currently running init container
kubectl logs init-container-slow -c init-download -f

# Check init container progress
kubectl describe pod init-container-slow | grep -A 20 "Init Containers"
```

### 3. Init Container Image Pull Issues

**Example Pod:** `samples/init-container-image-pull.yaml`

**Debugging Commands:**
```bash
# Deploy the example
kubectl apply -f samples/init-container-image-pull.yaml

# Check status (will show Init:1/2 with ImagePullBackOff)
kubectl get pod init-container-image-pull

# Check events for image pull errors
kubectl describe pod init-container-image-pull

# Check init container statuses
kubectl get pod init-container-image-pull -o jsonpath='{.status.initContainerStatuses[*].state.waiting.reason}'

# Check which images are being pulled
kubectl get pod init-container-image-pull -o jsonpath='{.spec.initContainers[*].image}'
```

### Init Container Status Understanding

**Status Meanings:**
- **`Init:N/M`** - N of M init containers have completed successfully
- **`Init:Error`** - An init container has failed
- **`Init:CrashLoopBackOff`** - An init container is repeatedly failing
- **`PodInitializing`** - All init containers completed, main containers starting
- **`Pending`** - Pod hasn't been scheduled or init containers haven't started

**Common Debugging Commands:**
```bash
# Check all init container logs
for container in $(kubectl get pod POD_NAME -o jsonpath='{.spec.initContainers[*].name}'); do
  echo "=== Init Container: $container ==="
  kubectl logs POD_NAME -c $container
done

# Check init container exit codes
kubectl get pod POD_NAME -o jsonpath='{range .status.initContainerStatuses[*]}{.name}{": "}{.lastState.terminated.exitCode}{"\n"}{end}'

# Check init container restart counts
kubectl get pod POD_NAME -o jsonpath='{range .status.initContainerStatuses[*]}{.name}{": "}{.restartCount}{"\n"}{end}'

# Monitor init container progress
kubectl get events --field-selector involvedObject.name=POD_NAME --sort-by='.lastTimestamp'
```

## 🧹 Cleanup Commands

```bash
# Delete example pods
kubectl delete pod crashloop-example
kubectl delete pod oom-example
kubectl delete pod pending-example
kubectl delete pod image-pull-error-example
kubectl delete pod terminating-example --force --grace-period=0
kubectl delete pod hostport-example

# Delete init container examples
kubectl delete pod init-container-failing
kubectl delete pod init-container-slow
kubectl delete pod init-container-image-pull

# Clean up debug pods
kubectl delete pod --selector=debug=true

# Remove stuck finalizers (if needed)
kubectl patch pod POD_NAME -p '{"metadata":{"finalizers":null}}'
```

