#!/bin/bash
# Verify Kubernetes Tools Installation
# This script checks if all tools are properly installed and configured

set -e

echo "🔍 Verifying Kubernetes tools installation..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists and show version
check_tool() {
    local tool=$1
    local version_flag=${2:-"--version"}
    
    if command -v "$tool" >/dev/null 2>&1; then
        local version_output
        version_output=$($tool $version_flag 2>/dev/null | head -1 || echo "version unknown")
        echo -e "✅ ${GREEN}$tool${NC} - $version_output"
        return 0
    else
        echo -e "❌ ${RED}$tool${NC} - not installed"
        return 1
    fi
}

# Function to check shell configuration
check_shell_config() {
    local shell_type
    if [[ $SHELL == *"zsh"* ]]; then
        shell_type="zsh"
        config_file="$HOME/.zshrc"
    else
        shell_type="bash"
        config_file="$HOME/.bashrc"
    fi
    
    echo "🐚 Checking $shell_type configuration ($config_file):"
    
    # Check kubectl completion
    if grep -q "kubectl completion" "$config_file" 2>/dev/null; then
        echo -e "✅ ${GREEN}kubectl completion${NC} configured"
    else
        echo -e "❌ ${RED}kubectl completion${NC} not configured"
    fi
    
    # Check aliases
    local aliases=("k=kubecolor" "kc=kubecolor" "kgp=" "kctx=" "kns=")
    for alias_check in "${aliases[@]}"; do
        if grep -q "alias $alias_check" "$config_file" 2>/dev/null; then
            echo -e "✅ ${GREEN}alias $alias_check${NC} configured"
        else
            echo -e "⚠️  ${YELLOW}alias $alias_check${NC} not configured"
        fi
    done
    echo ""
}

# Function to check kubectl context
check_kubectl_context() {
    echo "🔗 Checking kubectl context:"
    if kubectl cluster-info >/dev/null 2>&1; then
        local current_context
        current_context=$(kubectl config current-context 2>/dev/null || echo "none")
        echo -e "✅ ${GREEN}kubectl context${NC} - $current_context"
        
        # Show cluster info
        kubectl cluster-info --request-timeout=5s 2>/dev/null | head -2 || echo "Cluster info unavailable"
    else
        echo -e "❌ ${RED}kubectl context${NC} - no valid context or cluster unreachable"
    fi
    echo ""
}

# Function to check k9s configuration
check_k9s_config() {
    echo "🎯 Checking k9s configuration:"
    if [[ -f "$HOME/.config/k9s/config.yml" ]]; then
        echo -e "✅ ${GREEN}k9s config${NC} - $HOME/.config/k9s/config.yml exists"
    else
        echo -e "⚠️  ${YELLOW}k9s config${NC} - default configuration will be used"
    fi
    echo ""
}

# Main verification
echo "📋 Core Tools:"
check_tool "kubectl" "version --client --short"
check_tool "k9s" "version"
check_tool "kubecolor" "version"
check_tool "kubectx" "--help"
check_tool "kubens" "--help"
echo ""

echo "🛠️ Additional Tools:"
check_tool "stern" "--version"
check_tool "helm" "version --short"
check_tool "kustomize" "version --short"
check_tool "kubectl-tree" "--help"
check_tool "dive" "--version"
echo ""

# Check configurations
check_shell_config
check_kubectl_context
check_k9s_config

# Summary
echo "📊 Verification Summary:"
echo "Run this script anytime to check your Kubernetes tools setup."
echo ""
echo "🚀 Quick test commands:"
echo "   k version --short       # kubectl with alias"
echo "   kc get nodes            # colorized kubectl"
echo "   k9s info                # k9s cluster info"
echo "   kctx                    # list contexts"
echo "   stern --help            # stern usage"
echo ""
echo "💡 If any tools are missing, run:"
echo "   ./hack/setup-k8s-tools.sh"
echo "   ./hack/install-additional-tools.sh"
