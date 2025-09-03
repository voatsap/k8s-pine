# ArgoCD Deployment on k8s-pine

This directory contains the complete ArgoCD deployment configuration for the k8s-pine cluster, exposing ArgoCD via Cilium ingress controller on `k8s-pine-argocd.p10e.io`.

## 🚀 Quick Start

```bash
# Deploy ArgoCD
./install/deploy-argocd.sh

# Or deploy manually step by step:
kubectl apply -f install/argocd-namespace.yaml
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f install/argocd-config.yaml
kubectl apply -f install/argocd-cluster-admin.yaml
kubectl apply -f install/argocd-default-project.yaml
kubectl apply -f install/argocd-resource-exclusions.yaml
kubectl apply -f install/argocd-ingress.yaml

# Deploy example application
kubectl apply -f test-application.yaml

# Deploy sync wave examples (Helm charts)
kubectl apply -f helm-namespace-setup.yaml
kubectl apply -f helm-mysql-simple.yaml
kubectl apply -f helm-mysql-with-init.yaml
kubectl apply -f helm-test-client.yaml
```

## 🔐 Access Information

### Web UI Access
- **URL**: https://k8s-pine-argocd.p10e.io
- **Username**: `admin`
- **Password**: `I8H1QNTlpejOFvxb`

### CLI Access
```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login via CLI
argocd login k8s-pine-argocd.p10e.io --username admin --password I8H1QNTlpejOFvxb
```

## 📁 File Structure

```
examples/argo/
├── README.md                       # This file
├── README-sync-waves.md            # Sync waves documentation
├── test-application.yaml           # Example ArgoCD application (controller demo)
├── helm-namespace-setup.yaml      # Sync wave -1: Namespace setup
├── helm-mysql-simple.yaml         # Sync wave 1: Simple MySQL
├── helm-mysql-with-init.yaml      # Sync wave 2: MySQL with hooks
├── helm-test-client.yaml          # Sync wave 3: Test clients
├── helm-app-of-apps.yaml          # App-of-apps pattern
├── manifests/                      # Additional manifests
│   ├── namespaces/
│   │   └── mysql-namespaces.yaml  # Namespace definitions
│   └── test-clients/
│       └── mysql-test-pods.yaml   # Test pod definitions
└── install/                        # ArgoCD installation files
    ├── argocd-namespace.yaml       # Argo namespace definition
    ├── argocd-install.yaml         # Alternative job-based installer
    ├── argocd-config.yaml          # ArgoCD server configuration
    ├── argocd-ingress.yaml         # Cilium ingress configuration
    ├── argocd-cluster-admin.yaml   # Cluster admin permissions for ArgoCD
    ├── argocd-default-project.yaml # Default ArgoCD project
    ├── argocd-resource-exclusions.yaml # GKE resource exclusions
    └── deploy-argocd.sh            # Automated deployment script
```

## 🔧 Configuration Details

### Namespace
- **Name**: `argo`
- **Purpose**: Dedicated namespace for ArgoCD components

### Ingress Configuration
- **Controller**: Cilium
- **Domain**: `k8s-pine-argocd.p10e.io`
- **TLS**: Automatic certificate provisioning via cert-manager
- **DNS**: Automatic DNS record creation via external-dns
- **Load Balancer**: Cilium IPAM with automatic IP assignment

### Services
- **argocd-server**: Main ArgoCD server (ClusterIP)
- **argocd-server-nodeport**: NodePort service (backup access method)

### RBAC Configuration
- **Cluster Admin**: Full cluster-admin permissions for ArgoCD components
- **Comprehensive Access**: Complete access to all Kubernetes resources and APIs
- **GKE Compatibility**: Resource exclusions for GKE-specific APIs

## 🛠️ Management Commands

### Check Deployment Status
```bash
# Check all pods
kubectl get pods -n argo

# Check services
kubectl get services -n argo

# Check ingress
kubectl get ingress -n argo

# Check ArgoCD server logs
kubectl logs -n argo deployment/argocd-server

# Apply cluster admin permissions
kubectl apply -f argocd-cluster-admin.yaml

# Apply default project and resource exclusions
kubectl apply -f argocd-default-project.yaml
kubectl apply -f argocd-resource-exclusions.yaml
```

### Get Admin Password
```bash
kubectl -n argo get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port Forward (Alternative Access)
```bash
kubectl port-forward svc/argocd-server -n argo 8080:443
# Access via: https://localhost:8080
```

### Reset Admin Password
```bash
# Generate new password
kubectl -n argo patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "$2a$10$rRyBsGSHK6.uc8fntPwVIuLVHgsAhAX7TcdrqW/RADU0uh7CaChLa","admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'

# New password will be: password
```

## 🔍 Troubleshooting

### Common Issues

1. **Ingress not accessible**
   ```bash
   # Check ingress controller
   kubectl get pods -n kube-system | grep cilium
   
   # Check ingress status
   kubectl describe ingress argocd-server-ingress -n argo
   ```

2. **Certificate issues**
   ```bash
   # Check cert-manager
   kubectl get certificates -n argo
   kubectl describe certificate k8s-pine-argocd-tls-cert -n argo
   ```

3. **DNS resolution issues**
   ```bash
   # Check external-dns logs
   kubectl logs -n kube-system deployment/external-dns
   ```

4. **ArgoCD server not starting**
   ```bash
   # Check server logs
   kubectl logs -n argo deployment/argocd-server
   
   # Check configuration
   kubectl get configmap argocd-server-config -n argo -o yaml
   ```

### Health Checks
```bash
# Check ArgoCD application health
kubectl get applications -n argo

# Check ArgoCD server health
curl -k https://k8s-pine-argocd.p10e.io/healthz
```

## 🔄 Updating ArgoCD

```bash
# Update to latest stable version
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Restart components
kubectl rollout restart deployment/argocd-server -n argo
kubectl rollout restart deployment/argocd-repo-server -n argo
kubectl rollout restart statefulset/argocd-application-controller -n argo
```

## 🗑️ Cleanup

```bash
# Remove ArgoCD
kubectl delete -n argo -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete -f argocd-ingress.yaml
kubectl delete -f argocd-config.yaml
kubectl delete namespace argo
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD CLI Reference](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
- [Cilium Ingress Controller](https://docs.cilium.io/en/stable/network/servicemesh/ingress/)
- [cert-manager Documentation](https://cert-manager.io/docs/)

## 🔐 Security Notes

- Change the default admin password after first login
- Consider enabling RBAC and creating dedicated users
- Review and configure ArgoCD RBAC policies
- Enable audit logging for compliance requirements
- Use service accounts for CI/CD integrations

---

**Status**: ✅ Deployed and accessible at https://k8s-pine-argocd.p10e.io  
**Last Updated**: 2025-09-03T16:15:00+03:00
