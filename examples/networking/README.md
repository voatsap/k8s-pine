# Kubernetes Networking Examples

This directory contains examples for Kubernetes networking configurations, including ingress controllers, load balancing, and TLS certificate management.

## 📋 Overview

The examples demonstrate:
- **Application Load Balancing** with multiple nginx pod replicas
- **Cilium Ingress Configuration** with TLS termination
- **cert-manager Integration** for automatic certificate provisioning
- **External DNS** for automatic DNS record management
- **Cilium Gateway API** support (alternative to traditional Ingress)
- **Hubble UI Exposure** via Ingress from the kube-system namespace
- **NetworkPolicy Examples** for pod-to-pod security and traffic control

## 🚀 Quick Start

### Prerequisites

Ensure your cluster has the following components installed:
- **Cilium Ingress Controller** (using `cilium` IngressClass)
- **cert-manager** for TLS certificates with existing ClusterIssuer
- **External DNS** for DNS automation
- **Cilium Gateway API** support

### Test Pod Setup

For testing network connectivity and policies, deploy a curl pod:

```bash
kubectl run curl-test --image=curlimages/curl:latest --rm -it --restart=Never -- sleep 3600
```

Or use a persistent deployment:
```bash
kubectl apply -f curl-test-deployment.yaml
```

### Deploy the Example

1. **Deploy the application and service:**
   ```bash
   kubectl apply -f nginx-deployment.yaml
   kubectl apply -f nginx-service.yaml
   ```

2. **Deploy the Ingress:**
   ```bash
   kubectl apply -f nginx-ingress.yaml
   ```
   
   **Note**: The `cert-manager-clusterissuer.yaml` is for reference only. Use your existing `cloudflare-issuer` ClusterIssuer.

3. **Alternative: Cilium Gateway API**
   ```bash
   kubectl apply -f cilium-gateway-config.yaml
   ```

## 📁 File Descriptions

### `nginx-deployment.yaml`
- **Deployment**: 3 replica nginx pods with health checks
- **ConfigMap**: Custom HTML page showing load balancer status
- **Resource limits**: Memory and CPU constraints
- **Probes**: Liveness and readiness checks

### `nginx-service.yaml`
- **LoadBalancer Service**: External access with cloud provider LoadBalancer
- **External IP**: Automatic external IP assignment for internet access
- **Port 80**: HTTP traffic routing

### `nginx-ingress.yaml`
- **Ingress Resource**: Routes traffic to `k8s-pine.p10e.io`
- **IngressClass**: Uses `cilium` ingress controller
- **LoadBalancer Type**: External (configurable via annotation)
- **TLS Configuration**: Automatic certificate from `cloudflare-issuer`
- **Annotations**: 
  - cert-manager integration with cloudflare-issuer
  - External DNS automation
  - Force HTTPS redirect
  - External LoadBalancer type (default for demo)

### `cert-manager-clusterissuer.yaml`
- **Reference Configuration**: Example based on existing `cloudflare-issuer`
- **DNS-01 Challenge**: Cloudflare API for domain validation
- **Note**: For reference only - use existing `cloudflare-issuer` in cluster

### `cilium-gateway-config.yaml`
- **Gateway Resource**: Kubernetes Gateway API v1beta1 configuration using Cilium
- **Listeners**: HTTP (port 80) and HTTPS (port 443) with TLS termination
- **HTTPRoute**: Traffic routing rules for `k8s-pine-gw.p10e.io` domain
- **TLS Certificate**: References `k8s-pine-gw-tls-cert` secret for HTTPS
- **Backend Service**: Routes traffic to `nginx-service` on port 80
- **Alternative**: Modern Gateway API approach vs traditional Ingress

### `gateway-certificate.yaml`
- **Certificate**: Issues TLS cert for `k8s-pine-gw.p10e.io`
- **Issuer**: Uses existing `cloudflare-issuer` `ClusterIssuer`
- **Secret**: Stores cert/key in `k8s-pine-gw-tls-cert`

### `hubble-expose.yaml`
- **Service (default namespace)**: `k8s-pine-hubble` (ClusterIP)
- **Endpoints (default namespace)**: Points to `hubble-ui` LoadBalancer IP in `kube-system` (port 80)
- **Ingress (default namespace)**: Exposes `k8s-pine-hubble.p10e.io` with TLS via `cloudflare-issuer` and ExternalDNS annotations

### NetworkPolicy Examples

#### `networkpolicy-deny-all.yaml`
- **Basic Security**: Deny all ingress and egress traffic by default
- **Zero-Trust**: Starting point for secure networking
- **Scope**: Apply to all pods or specific apps via podSelector

#### `networkpolicy-allow-specific.yaml`
- **Selective Access**: Allow traffic between specific pods (frontend ↔ backend)
- **Port Control**: Restrict access to specific ports only
- **Multi-tier**: Database access from backend and admin pods

#### `networkpolicy-namespace-isolation.yaml`
- **Namespace Security**: Control traffic between different namespaces
- **Environment Isolation**: Separate dev/staging/production traffic
- **Cross-namespace**: Allow specific namespaces while blocking others

#### `networkpolicy-egress-control.yaml`
- **Outbound Security**: Control what external services pods can access
- **IP Blocking**: Block access to internal networks from untrusted apps
- **DNS Control**: Allow DNS resolution while restricting other traffic
- **Cilium FQDN**: Domain-based egress control (Cilium-specific)

#### `networkpolicy-common-patterns.yaml`
- **Three-tier Architecture**: Frontend → Backend → Database patterns
- **Microservices**: Service-to-service communication rules
- **Development Isolation**: Separate dev environments securely
- **Monitoring Access**: Allow Prometheus and logging tools

## 🔧 Configuration Details

### Domain Configuration
- **Domain**: `k8s-pine.p10e.io`
- **TLS Secret**: `k8s-pine-tls-cert`
- **Certificate Issuer**: `cloudflare-issuer` (existing ClusterIssuer)

### LoadBalancer Configuration
- **Service Type**: LoadBalancer with External IP
- **Ingress Type**: External (configurable via annotation)
- **Switch to Internal**: Change annotation to `cloud.google.com/load-balancer-type: "Internal"`

### Gateway API vs Traditional Ingress

**Traditional Ingress (`nginx-ingress.yaml`):**
- Uses `networking.k8s.io/v1` Ingress resource
- Single resource for routing configuration
- Annotations for controller-specific features
- IngressClass: `cilium`

**Gateway API (`cilium-gateway-config.yaml`):**
- Uses `gateway.networking.k8s.io/v1beta1` Gateway and HTTPRoute resources
- Separation of infrastructure (Gateway) and routing (HTTPRoute) concerns
- More expressive and standardized configuration
- Better support for advanced traffic management

### Load Balancing
- **Algorithm**: Round-robin
- **Session Affinity**: IP-based hashing
- **Health Checks**: HTTP probes on port 80

### Security Features
- **Force HTTPS**: Automatic SSL redirect via `ingress.cilium.io/force-https: "true"`
- **TLS Certificate**: Valid Let's Encrypt certificate via Cloudflare DNS validation
- **Certificate Verification**: TLSv1.3 with TLS_AES_256_GCM_SHA384

## 🛠️ Troubleshooting

### Check Application Status
```bash
# Verify pods are running
kubectl get pods -l app=nginx-app

# Check service endpoints
kubectl get endpoints nginx-service

# View ingress status
kubectl get ingress nginx-ingress
```

### Certificate Issues
```bash
# Check certificate status
kubectl get certificate k8s-pine-tls-cert

# View cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate details
kubectl describe certificate k8s-pine-tls-cert
```

### DNS Resolution
```bash
# Check external-dns logs
kubectl logs -n external-dns deployment/external-dns

# Verify DNS record creation
nslookup k8s-pine.p10e.io
```

**Gateway API note**:
- If using ExternalDNS, ensure it watches Gateway API resources (e.g., add `--source=gateway-httproute`).
- Otherwise, create a manual DNS record for `k8s-pine-gw.p10e.io` → the Gateway external IP, or use a `DNSEndpoint` resource if supported by your deployment.

### Gateway API (Cilium)
```bash
# Check gateway status
kubectl get gateway k8s-pine-gateway

# View HTTPRoute status
kubectl get httproute nginx-route

# Check gateway configuration details
kubectl describe gateway k8s-pine-gateway
kubectl describe httproute nginx-route

# Check Cilium gateway logs
kubectl logs -n kube-system daemonset/cilium
```

## 🛡️ NetworkPolicy Usage

### Understanding NetworkPolicies

NetworkPolicies provide **network-level security** by controlling traffic flow between pods. Think of them as **firewall rules** for your Kubernetes applications.

**Key Concepts:**
- **Default Behavior**: Without NetworkPolicies, all pods can communicate freely
- **Deny by Default**: Once a NetworkPolicy is applied, it blocks all traffic except what's explicitly allowed
- **Pod Selection**: Use `podSelector` to target specific pods by labels
- **Traffic Direction**: Control `ingress` (incoming) and `egress` (outgoing) traffic separately

### Quick Start with NetworkPolicies

1. **Start with Deny-All** (recommended for security):
   ```bash
   kubectl apply -f networkpolicy-deny-all.yaml
   ```

2. **Add Specific Allow Rules**:
   ```bash
   kubectl apply -f networkpolicy-allow-specific.yaml
   ```

3. **Test Your Policies**:
   ```bash
   # This should work (allowed traffic)
   kubectl exec frontend-pod -- curl backend-service:8080
   
   # This should fail (blocked traffic)
   kubectl exec untrusted-pod -- curl backend-service:8080
   ```

### Exercise Examples

**Exercise 1: Three-Tier Security**
```bash
# Apply the three-tier pattern
kubectl apply -f networkpolicy-common-patterns.yaml

# Label your pods correctly
kubectl label pod frontend-pod tier=frontend
kubectl label pod backend-pod tier=backend  
kubectl label pod database-pod tier=database

# Test the security boundaries
kubectl exec frontend-pod -- curl backend-service:8080  # ✅ Should work
kubectl exec frontend-pod -- curl database-service:5432 # ❌ Should fail
```

**Exercise 2: Namespace Isolation**
```bash
# Create test namespaces
kubectl create namespace development
kubectl create namespace production

# Apply isolation policies
kubectl apply -f networkpolicy-namespace-isolation.yaml

# Test cross-namespace access
kubectl run test-pod --image=nginx -n development
kubectl run test-pod --image=nginx -n production
```

### Common Troubleshooting

**Policy Not Working?**
```bash
# Check if NetworkPolicy is applied
kubectl get networkpolicy

# Verify pod labels match selectors
kubectl get pods --show-labels

# Check Cilium status
kubectl get pods -n kube-system -l k8s-app=cilium
```

**DNS Issues?**
```bash
# Always allow DNS in egress rules
egress:
- to: []
  ports:
  - protocol: UDP
    port: 53
```

## 🌐 Testing the Setup

### External Access Testing

1. **Direct LoadBalancer access:**
   ```bash
   # Get external IP
   kubectl get svc nginx-service
   
   # Test direct access (replace with actual external IP)
   curl http://35.245.114.11
   ```

2. **Domain access (if DNS is configured):**
   ```bash
   curl https://k8s-pine.p10e.io
   ```

3. **Gateway access (if DNS is configured):**
   ```bash
   # Replace <GW_IP> with Gateway ADDRESS from `kubectl get gateway`
   # Test via IP + Host header
   curl -H "Host: k8s-pine-gw.p10e.io" http://<GW_IP>
   # If DNS is configured
   curl https://k8s-pine-gw.p10e.io
   ```

### Internal Cluster Testing

**Test from within cluster using existing curl pod:**

1. **HTTP to HTTPS redirect test:**
   ```bash
   kubectl exec curl-test -- curl -I http://k8s-pine.p10e.io
   # Expected: 301 Moved Permanently → https://k8s-pine.p10e.io/
   ```

2. **HTTPS access test:**
   ```bash
   kubectl exec curl-test -- curl -I https://k8s-pine.p10e.io
   # Expected: 200 OK
   ```

3. **Full application test:**
   ```bash
   kubectl exec curl-test -- curl https://k8s-pine.p10e.io
   # Expected: K8s Pine HTML page
   ```

4. **Certificate verification:**
   ```bash
   kubectl exec curl-test -- curl -v https://k8s-pine.p10e.io 2>&1 | grep -E "(certificate|SSL|TLS|subject|issuer)"
   # Expected: Valid Let's Encrypt certificate with CN=k8s-pine.p10e.io
   ```

### Load Balancing Verification

```bash
# Multiple requests should show different pod responses
for i in {1..5}; do 
  kubectl exec curl-test -- curl -s https://k8s-pine.p10e.io | grep "Pod Hostname"
done
```

## 📚 Additional Resources

- [Cilium Ingress Controller](https://docs.cilium.io/en/stable/network/servicemesh/ingress/)
- [cert-manager Documentation](https://cert-manager.io/docs/)
- [External DNS](https://github.com/kubernetes-sigs/external-dns)
- [Cilium Gateway API](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## ⚠️ Important Notes

- **ClusterIssuer**: Use existing `cloudflare-issuer` - do not apply `cert-manager-clusterissuer.yaml`
- **IngressClass**: Uses `cilium` ingress controller (verified in cluster)
- **LoadBalancer Type**: External by default for demo - change annotation for internal access
- **DNS Provider**: External DNS configured for Cloudflare
- **Testing**: Use internal cluster testing with curl pod for reliable verification
- **Resource Limits**: Adjust CPU/memory limits based on your cluster capacity

## 🎯 Quick Verification

```bash
# Check all components are running
kubectl get pods -l app=nginx-app
kubectl get svc nginx-service  
kubectl get ingress nginx-ingress
kubectl get certificate k8s-pine-tls-cert

# Test from cluster (most reliable)
kubectl exec curl-test -- curl -I https://k8s-pine.p10e.io
```
