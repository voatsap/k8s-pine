#!/bin/bash

# ArgoCD Deployment Script for k8s-pine
# This script deploys ArgoCD in the argo namespace and exposes it via ingress

set -e

echo "🚀 Starting ArgoCD deployment..."

# Create namespace
echo "📁 Creating argo namespace..."
kubectl apply -f install/argocd-namespace.yaml

# Wait for namespace to be ready
kubectl wait --for=condition=Ready namespace/argo --timeout=30s

# Install ArgoCD
echo "⚙️  Installing ArgoCD..."
kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD components to be ready
echo "⏳ Waiting for ArgoCD components to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-repo-server -n argo
kubectl wait --for=condition=available --timeout=300s deployment/argocd-application-controller -n argo

# Apply configuration
echo "🔧 Applying ArgoCD configuration..."
kubectl apply -f install/argocd-config.yaml

# Apply cluster admin permissions
echo "🔐 Applying cluster admin permissions..."
kubectl apply -f install/argocd-cluster-admin.yaml

# Apply default project and resource exclusions
echo "📋 Applying default project and resource exclusions..."
kubectl apply -f install/argocd-default-project.yaml
kubectl apply -f install/argocd-resource-exclusions.yaml

# Restart ArgoCD components to pick up new config
echo "🔄 Restarting ArgoCD components..."
kubectl rollout restart deployment/argocd-server -n argo
kubectl rollout restart statefulset/argocd-application-controller -n argo
kubectl rollout status deployment/argocd-server -n argo
kubectl rollout status statefulset/argocd-application-controller -n argo

# Apply ingress
echo "🌐 Setting up ingress..."
kubectl apply -f install/argocd-ingress.yaml

# Get admin password
echo "🔑 Retrieving admin password..."
ADMIN_PASSWORD=$(kubectl -n argo get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✅ ArgoCD deployment completed!"
echo ""
echo "🔗 Access URLs:"
echo "   Web UI: https://k8s-pine-argocd.p10e.io"
echo "   NodePort: https://localhost:30443 (if port-forwarding)"
echo ""
echo "🔐 Login Credentials:"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "📝 To port-forward for local access:"
echo "   kubectl port-forward svc/argocd-server -n argo 8080:443"
echo "   Then access: https://localhost:8080"
echo ""
echo "🔍 Check status:"
echo "   kubectl get pods -n argo"
echo "   kubectl get ingress -n argo"
