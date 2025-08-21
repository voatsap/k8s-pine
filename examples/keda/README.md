# KEDA (Kubernetes Event-Driven Autoscaling) Examples

This directory contains comprehensive examples of KEDA-based autoscaling for event-driven workloads in Kubernetes.

## ConfigMap as Script Design Approach

### KEDA Installation Scripts
The installation examples use **ConfigMaps** to store executable shell scripts for KEDA deployment. This design provides:

- ** Executable Scripts**: Scripts can be extracted and run directly for KEDA installation
- ** Version Control**: Installation scripts are stored as Kubernetes resources
- ** Multiple Methods**: Both Helm and kubectl installation approaches included
- ** Automation Ready**: Easy integration with CI/CD pipelines and cluster setup

### Usage Examples
```bash
# Install KEDA using Helm (recommended)
kubectl apply -f keda-install.yaml
kubectl get configmap keda-install-script -n keda -o jsonpath='{.data.install-keda\.sh}' | bash

# Alternative: Install using kubectl
kubectl get configmap keda-kubectl-install -n keda -o jsonpath='{.data.install-keda-kubectl\.sh}' | bash
```

## 📁 Available Examples

### KEDA Installation
- **`keda-install.yaml`** - ConfigMaps with executable scripts for KEDA installation (Helm & kubectl methods)

### RabbitMQ Scaling
- **`rabbitmq-scaler.yaml`** - Complete RabbitMQ consumer scaling setup with KEDA ScaledObject
- **`message-producer.yaml`** - Message producer job and CronJob for testing scaling behavior

## 🚀 Quick Start

### 1. Install KEDA
```bash
# Apply KEDA installation resources
kubectl apply -f examples/keda/keda-install.yaml

# Install KEDA using Helm (recommended)
kubectl get configmap keda-install-script -n keda -o jsonpath='{.data.install-keda\.sh}' | bash

# Verify KEDA installation
kubectl get pods -n keda
kubectl get crd | grep keda
```

### 2. Deploy RabbitMQ Scaling Example
```bash
# Deploy RabbitMQ and consumer with KEDA scaling
kubectl apply -f examples/keda/rabbitmq-scaler.yaml

# Check initial deployment
kubectl get pods
kubectl get scaledobjects
```

### 3. Test Scaling Behavior
```bash
# Generate messages to trigger scaling
kubectl apply -f examples/keda/message-producer.yaml

# Monitor scaling in real-time
kubectl get pods -w
kubectl get hpa -w

# Check KEDA metrics
kubectl describe scaledobject rabbitmq-consumer-scaler
```

## 📊 KEDA Scaling Configuration

### RabbitMQ Scaler Details

**Scaling Trigger**:
- **Queue**: `task_queue`
- **Threshold**: 5 messages per replica
- **Min Replicas**: 1
- **Max Replicas**: 10

**Authentication**:
- Uses Kubernetes Secret for RabbitMQ credentials
- TriggerAuthentication for secure connection

**Consumer Behavior**:
- Processes 1 message at a time (QoS=1)
- 5-second processing time per message
- Automatic message acknowledgment

## 🔧 Monitoring KEDA

### KEDA Status Commands
```bash
# Check KEDA operator status
kubectl get pods -n keda

# View ScaledObject details
kubectl get scaledobjects
kubectl describe scaledobject rabbitmq-consumer-scaler

# Monitor HPA created by KEDA
kubectl get hpa
kubectl describe hpa keda-hpa-rabbitmq-consumer-scaler

# Check scaling events
kubectl get events --sort-by=.metadata.creationTimestamp | grep -i keda
```

### RabbitMQ Monitoring
```bash
# Access RabbitMQ Management UI (port-forward)
kubectl port-forward service/rabbitmq-service 15672:15672

# Check queue length
kubectl exec -it deployment/rabbitmq -- rabbitmqctl list_queues name messages

# Monitor consumer pods
kubectl get pods -l app=rabbitmq-consumer -w
```

## 🧪 Testing Scenarios

### Scenario 1: Manual Load Testing
```bash
# 1. Deploy the scaling setup
kubectl apply -f examples/keda/rabbitmq-scaler.yaml

# 2. Generate a burst of messages
kubectl apply -f examples/keda/message-producer.yaml

# 3. Watch scaling behavior
kubectl get pods -l app=rabbitmq-consumer -w

# 4. Monitor queue length and scaling metrics
kubectl describe scaledobject rabbitmq-consumer-scaler
```

### Scenario 2: Continuous Load Testing
```bash
# 1. Enable CronJob for continuous message generation
kubectl apply -f examples/keda/message-producer.yaml

# 2. Monitor long-term scaling behavior
kubectl get pods -l app=rabbitmq-consumer --watch-only

# 3. Check scaling statistics
kubectl get events --field-selector involvedObject.name=rabbitmq-consumer-scaler
```

### Scenario 3: Scale-to-Zero Testing
```bash
# 1. Stop message generation
kubectl delete cronjob rabbitmq-load-generator

# 2. Wait for queue to drain
kubectl exec -it deployment/rabbitmq -- rabbitmqctl list_queues

# 3. Observe scale-down to minimum replicas
kubectl get pods -l app=rabbitmq-consumer -w
```

## 🛠️ Customization Options

### Scaling Parameters
```yaml
# Modify scaling behavior in rabbitmq-scaler.yaml
spec:
  minReplicaCount: 1          # Minimum pods (scale-to-zero: set to 0)
  maxReplicaCount: 10         # Maximum pods
  triggers:
  - type: rabbitmq
    metadata:
      queueName: task_queue
      value: "5"              # Messages per replica threshold
      mode: QueueLength       # or MessageRate
```

### Advanced Scaling Policies
```yaml
# Add advanced scaling behavior
spec:
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300
          policies:
          - type: Percent
            value: 50
            periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 60
          policies:
          - type: Pods
            value: 2
            periodSeconds: 60
```

## 🧹 Cleanup

```bash
# Remove KEDA examples
kubectl delete -f examples/keda/rabbitmq-scaler.yaml
kubectl delete -f examples/keda/message-producer.yaml

# Uninstall KEDA (if using Helm)
helm uninstall keda -n keda

# Remove KEDA namespace
kubectl delete namespace keda
```

## 📚 Additional Resources

- [KEDA Documentation](https://keda.sh/docs/)
- [KEDA RabbitMQ Scaler](https://keda.sh/docs/scalers/rabbitmq-queue/)
- [KEDA ScaledObject Specification](https://keda.sh/docs/concepts/scaling-deployments/)
- [KEDA Authentication](https://keda.sh/docs/concepts/authentication/)
- [KEDA Helm Charts](https://github.com/kedacore/charts)

## 💡 Tips

- Start with small queue thresholds (5-10 messages) for responsive scaling
- Use TriggerAuthentication for secure credential management
- Monitor both KEDA metrics and application performance
- Test scale-to-zero behavior in non-production environments first
- Consider message processing time when setting scaling thresholds
- Use RabbitMQ management UI for queue monitoring and debugging
- Combine KEDA with resource-based HPA for comprehensive scaling strategies
