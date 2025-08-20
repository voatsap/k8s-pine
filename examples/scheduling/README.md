# Kubernetes Scheduling Examples

This directory contains comprehensive examples of Kubernetes scheduling features for advanced pod placement and workload distribution across nodes.

##  Configmap as Script Design Approach

### ConfigMap-Based Taint Scripts
The taint examples use **ConfigMaps** to store executable shell scripts rather than just documentation. This design provides:

- ** Executable Scripts**: Scripts can be extracted and run directly or executed inside pods
- ** Version Control**: Scripts are stored as Kubernetes resources, making them deployable via GitOps
- ** Dynamic Discovery**: Scripts use `kubectl get nodes -o jsonpath='{.items[0].metadata.name}'` instead of hardcoded node names
- ** RBAC Integration**: Can be executed via Jobs with controlled permissions (see `taint-executor-job.yaml`)
- ** Automation Ready**: Easy integration with CI/CD pipelines and cluster automation

### Usage Examples
```bash
# Direct execution
kubectl get configmap taint-gpu-nodes-script -o jsonpath='{.data.taint-nodes\.sh}' | bash

# Extract for automation
kubectl get configmap taint-gpu-nodes-script -o jsonpath='{.data.taint-nodes\.sh}' > setup.sh
chmod +x setup.sh && ./setup.sh

# Job-based execution (see taint-executor-job.yaml)
kubectl apply -f taint-executor-job.yaml
```

## 📁 Available Examples

### Taints & Tolerations
- **`taint-gpu-node.yaml`** - ConfigMap with executable script to taint nodes for GPU workloads
- **`toleration-gpu-pod.yaml`** - Pod with GPU node toleration
- **`taint-infra-node.yaml`** - ConfigMap with executable script to taint nodes for infrastructure workloads
- **`toleration-infra-pod.yaml`** - Pod tolerating infrastructure taints
- **`taint-dedicated-workload.yaml`** - ConfigMap with executable script for dedicated workload node taints
- **`toleration-dedicated-pod.yaml`** - Pod for dedicated workloads
- **`taint-executor-job.yaml`** - Job example for executing taint scripts with RBAC

### Pod/Node Affinity & Anti-Affinity
- **`node-affinity-required.yaml`** - Hard node affinity requirements
- **`node-affinity-preferred.yaml`** - Soft node affinity preferences
- **`pod-affinity-required.yaml`** - Hard pod affinity (co-location)
- **`pod-affinity-preferred.yaml`** - Soft pod affinity preferences
- **`pod-anti-affinity-required.yaml`** - Hard pod anti-affinity (spread)
- **`pod-anti-affinity-preferred.yaml`** - Soft pod anti-affinity preferences

### Topology Spread Constraints
- **`topology-spread-zones.yaml`** - Spread pods across availability zones
- **`topology-spread-nodes.yaml`** - Spread pods across nodes
- **`topology-spread-mixed.yaml`** - Multiple topology constraints
- **`topology-spread-skew.yaml`** - Custom skew configurations

### Scheduling Policies
- **`scheduling-policy-required.yaml`** - Hard scheduling requirements
- **`scheduling-policy-preferred.yaml`** - Soft scheduling preferences
- **`scheduling-policy-mixed.yaml`** - Combined hard and soft rules

### Horizontal Pod Autoscaler (HPA)
- **`hpa-simple-example.yaml`** - CPU/Memory-based autoscaling (scales at >5% CPU load)

## 🚀 Quick Start Commands

### Apply Scheduling Examples
```bash
# Apply all scheduling examples
k apply -f examples/scheduling/

# Apply specific category
k apply -f examples/scheduling/taint-*.yaml
k apply -f examples/scheduling/node-affinity-*.yaml
k apply -f examples/scheduling/topology-*.yaml
k apply -f examples/scheduling/hpa-*.yaml
```

### Basic Scheduling Commands

#### Node Management
```bash
# List all nodes with labels
k get nodes --show-labels

# Add labels to nodes
k label nodes NODE_NAME workload-type=gpu
k label nodes NODE_NAME zone=us-central1-a
k label nodes NODE_NAME instance-type=n1-standard-4

# Add taints to nodes
k taint nodes NODE_NAME workload=gpu:NoSchedule
k taint nodes NODE_NAME dedicated=infra:NoExecute

# Remove taints from nodes
k taint nodes NODE_NAME workload=gpu:NoSchedule-
k taint nodes NODE_NAME dedicated=infra:NoExecute-
```

#### Pod Scheduling Information
```bash
# Check pod scheduling status
k get pods -o wide

# Describe pod for scheduling details
k describe pod POD_NAME

# Check pod events for scheduling issues
k get events --field-selector involvedObject.name=POD_NAME

# View node capacity and allocation
k describe nodes
k top nodes
```

## 🏷️ Taints & Tolerations Examples

Taints repel pods from nodes unless the pod has a matching toleration. Perfect for GPU nodes, infrastructure nodes, or dedicated workloads.

### Understanding Taints & Tolerations

**Taint Effects:**
- **NoSchedule** - New pods won't be scheduled (existing pods remain)
- **PreferNoSchedule** - Avoid scheduling if possible (soft)
- **NoExecute** - Evict existing pods and prevent new ones

**Toleration Operators:**
- **Equal** - Exact key-value match
- **Exists** - Key exists (ignores value)

### Apply Taint Examples

```bash
# Apply GPU node taint and test pod
k apply -f taint-gpu-node.yaml
k apply -f toleration-gpu-pod.yaml

# Apply infrastructure node taint and test pod
k apply -f taint-infra-node.yaml
k apply -f toleration-infra-pod.yaml

# Check pod placement
k get pods -o wide
k describe pod gpu-workload
k describe pod infra-workload
```

### Test Taint Behavior

```bash
# Create a regular pod (should avoid tainted nodes)
k run regular-pod --image=nginx

# Create pod with toleration (should schedule on tainted nodes)
k apply -f toleration-gpu-pod.yaml

# Check scheduling results
k get pods -o wide
k get events | grep -E "(gpu-workload|regular-pod)"
```

## 🎯 Pod/Node Affinity & Anti-Affinity Examples

Control pod placement based on node properties or other pod locations.

### Understanding Affinity Types

**Node Affinity:**
- **requiredDuringSchedulingIgnoredDuringExecution** - Hard requirement
- **preferredDuringSchedulingIgnoredDuringExecution** - Soft preference

**Pod Affinity/Anti-Affinity:**
- **Affinity** - Schedule pods together (co-location)
- **Anti-Affinity** - Schedule pods apart (spread)

### Apply Affinity Examples

```bash
# Apply node affinity examples
k apply -f node-affinity-required.yaml
k apply -f node-affinity-preferred.yaml

# Apply pod affinity examples
k apply -f pod-affinity-required.yaml
k apply -f pod-affinity-preferred.yaml

# Apply pod anti-affinity examples
k apply -f pod-anti-affinity-required.yaml
k apply -f pod-anti-affinity-preferred.yaml

# Check pod placement patterns
k get pods -o wide --sort-by=.spec.nodeName
```

### Test Affinity Behavior

```bash
# Scale deployments to see affinity in action
k scale deployment web-frontend --replicas=4
k scale deployment cache-redis --replicas=3

# Check how pods are distributed
k get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase

# View scheduling decisions
k describe pods | grep -A 10 "Node-Selectors\|Tolerations\|Affinity"
```

## 🌐 Topology Spread Constraints Examples

Distribute pods across zones, nodes, or custom topology domains for high availability.

### Understanding Topology Spread

**Key Concepts:**
- **topologyKey** - Node label to spread across (zone, node, rack)
- **maxSkew** - Maximum difference in pod count between domains
- **whenUnsatisfiable** - Action when constraint can't be met (DoNotSchedule/ScheduleAnyway)

### Apply Topology Spread Examples

```bash
# Apply zone-based spreading
k apply -f topology-spread-zones.yaml

# Apply node-based spreading
k apply -f topology-spread-nodes.yaml

# Apply mixed topology constraints
k apply -f topology-spread-mixed.yaml

# Scale to see spreading behavior
k scale deployment zone-spread-app --replicas=8
k scale deployment node-spread-app --replicas=6

# Check distribution
k get pods -o wide --sort-by=.spec.nodeName
```

### Analyze Topology Distribution

```bash
# Check pod distribution by zone
k get pods -o wide | awk '{print $7}' | sort | uniq -c

# Check pod distribution by node
k get pods -o wide | awk '{print $6}' | sort | uniq -c

# View topology spread status
k describe pods | grep -A 5 "Topology Spread Constraints"
```

## ⚖️ Scheduling Policies Examples

Combine hard requirements and soft preferences for optimal pod placement.

### Policy Types

**Required (Hard Rules):**
- Must be satisfied for scheduling
- Pod remains pending if not satisfied
- Uses `requiredDuringScheduling`

**Preferred (Soft Rules):**
- Best effort scheduling
- Pod can still schedule if not satisfied
- Uses `preferredDuringScheduling`

### Apply Scheduling Policy Examples

```bash
# Apply hard scheduling requirements
k apply -f scheduling-required-hard.yaml

# Apply soft scheduling preferences
k apply -f scheduling-preferred-soft.yaml

# Apply mixed scheduling policies
k apply -f scheduling-mixed-policies.yaml

# Test scheduling behavior
k get pods -o wide
k describe pod critical-app
k describe pod flexible-app
```

## 🔍 Troubleshooting Scheduling Issues

### Common Scheduling Problems

```bash
# Check pending pods
k get pods --field-selector=status.phase=Pending

# Analyze scheduling failures
k describe pod PENDING_POD_NAME

# Check node resources
k describe nodes | grep -A 5 "Allocated resources"

# View scheduler events
k get events --sort-by=.metadata.creationTimestamp | grep -i schedul
```

### Debug Scheduling Decisions

```bash
# Check why pod is not scheduled
debug_scheduling() {
    local pod_name=$1
    
    echo "=== POD STATUS ==="
    k get pod $pod_name -o wide
    
    echo "=== SCHEDULING CONDITIONS ==="
    k get pod $pod_name -o jsonpath='{.status.conditions[*].message}'
    
    echo "=== EVENTS ==="
    k get events --field-selector involvedObject.name=$pod_name
    
    echo "=== NODE RESOURCES ==="
    k describe nodes | grep -A 10 "Allocated resources"
    
    echo "=== TAINTS ==="
    k describe nodes | grep -A 3 "Taints"
}

# Usage
debug_scheduling "problematic-pod"
```

### Scheduling Best Practices

```bash
# 1. Check node capacity before scaling
k describe nodes | grep -E "(cpu|memory).*requests"

# 2. Monitor resource utilization
k top nodes
k top pods

# 3. Verify node labels for affinity rules
k get nodes --show-labels

# 4. Test scheduling policies with small replicas first
k scale deployment test-app --replicas=2

# 5. Use soft preferences when possible for flexibility
# Prefer preferredDuringScheduling over requiredDuringScheduling
```

## 🧪 Testing Scheduling Features

### Test Scenario 1: GPU Workload Isolation

```bash
# 1. Taint one node for GPU workloads
NODE1=$(k get nodes -o jsonpath='{.items[0].metadata.name}')
k taint nodes $NODE1 workload=gpu:NoSchedule

# 2. Deploy regular workload (should avoid GPU node)
k run regular-app --image=nginx --replicas=3

# 3. Deploy GPU workload (should only run on GPU node)
k apply -f toleration-gpu-pod.yaml

# 4. Verify placement
k get pods -o wide
```

### Test Scenario 2: High Availability Spread

```bash
# 1. Deploy app with zone anti-affinity
k apply -f pod-anti-affinity-required.yaml

# 2. Scale to see spreading
k scale deployment ha-web-app --replicas=4

# 3. Check distribution across zones
k get pods -o wide | grep ha-web-app
```

### Test Scenario 3: Co-location Requirements

```bash
# 1. Deploy cache service
k apply -f pod-affinity-required.yaml

# 2. Deploy web app that requires co-location with cache
k scale deployment web-with-cache --replicas=2

# 3. Verify pods are co-located
k get pods -o wide --sort-by=.spec.nodeName
```

## 📊 Monitoring Scheduling Metrics

### Scheduling Statistics

```bash
# Count pods per node
k get pods -o wide --no-headers | awk '{print $6}' | sort | uniq -c

# Count pods per zone (if zone labels exist)
k get pods -o wide --no-headers | awk '{print $7}' | sort | uniq -c

# Check pending pods
k get pods --field-selector=status.phase=Pending --no-headers | wc -l

# Monitor scheduling events
k get events --sort-by=.metadata.creationTimestamp | grep -i "schedul\|bind"
```

### Resource Utilization

```bash
# Node resource usage
k top nodes --sort-by=cpu
k top nodes --sort-by=memory

# Pod resource usage
k top pods --sort-by=cpu
k top pods --sort-by=memory

# Detailed node capacity
k describe nodes | grep -A 15 "Capacity:\|Allocatable:"
```

### Test Scenario 4: Horizontal Pod Autoscaler

```bash
# 1. Deploy HPA examples
k apply -f hpa-simple-example.yaml

# 2. Check HPA status
k get hpa
k describe hpa web-app-hpa

# 3. Monitor autoscaling behavior
k get pods -w

# 4. Generate load to trigger scaling (in separate terminal)
k run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh
# Inside the pod:
while true; do wget -q -O- http://web-app-hpa-service/; done

# 5. Watch HPA metrics and scaling events
k get hpa -w
k get events --sort-by=.metadata.creationTimestamp | grep -i hpa
```

## 🧹 Cleanup Scheduling Examples

```bash
# Remove all scheduling test resources
k delete -f examples/scheduling/ --ignore-not-found=true

# Remove taints from nodes
k get nodes -o jsonpath='{.items[*].metadata.name}' | xargs -I {} k taint nodes {} workload-
k get nodes -o jsonpath='{.items[*].metadata.name}' | xargs -I {} k taint nodes {} dedicated-

# Remove custom labels (optional)
k get nodes -o jsonpath='{.items[*].metadata.name}' | xargs -I {} k label nodes {} workload-type-
k get nodes -o jsonpath='{.items[*].metadata.name}' | xargs -I {} k label nodes {} zone-

# Clean up any remaining test pods
k get pods | grep -E "(test|demo|example)" | awk '{print $1}' | xargs -r k delete pod
```

## 📚 Additional Resources

- [Kubernetes Scheduling Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/)
- [Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
- [Assigning Pods to Nodes](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/)
- [Topology Spread Constraints](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

## 💡 Tips

- Start with soft preferences (`preferredDuringScheduling`) before using hard requirements
- Test scheduling policies with small replica counts first
- Monitor node resources to avoid over-scheduling
- Use topology spread constraints for high availability
- Combine multiple scheduling features for complex requirements
- Always have cleanup procedures ready for testing environments
