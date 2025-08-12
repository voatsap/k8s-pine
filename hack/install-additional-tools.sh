#!/bin/bash
# Install Additional Kubernetes Tools
# This script installs optional but useful Kubernetes tools

set -e

# Configuration variables
BIN_DIR="/usr/local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETIONS_DIR="$HOME/.oh-my-zsh/completions"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "🛠️ Installing additional Kubernetes tools..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect shell
detect_shell() {
    if [[ $SHELL == *"zsh"* ]]; then
        echo "zsh"
    else
        echo "bash"
    fi
}

SHELL_TYPE=$(detect_shell)

# Install stern (multi-pod log tailing)
echo "📋 Installing stern..."
if command_exists stern; then
    echo "✅ stern already installed ($(stern --version))"
else
    STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "Installing stern version: $STERN_VERSION"
    
    # Detect architecture and OS
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    cd "$TEMP_DIR"
    curl -LO "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_${OS}_${ARCH}.tar.gz"
    tar -xzf stern_${STERN_VERSION#v}_${OS}_${ARCH}.tar.gz
    sudo mv stern "$BIN_DIR/"
    cd - >/dev/null
    echo "✅ stern installed successfully"
    
    # Add completion
    if [[ $SHELL_TYPE == "bash" ]]; then
        stern --completion bash > /tmp/stern_completion
        sudo mv /tmp/stern_completion "$COMPLETION_DIR/stern"
    fi
fi

# Install helm
echo "⎈ Installing Helm..."
if command_exists helm; then
    echo "✅ Helm already installed ($(helm version --short))"
else
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "✅ Helm installed successfully"
    
    # Add completion
    if [[ $SHELL_TYPE == "zsh" ]]; then
        mkdir -p "$ZSH_COMPLETIONS_DIR" 2>/dev/null || true
        helm completion zsh > "$ZSH_COMPLETIONS_DIR/_helm"
    else
        helm completion bash > /tmp/helm_completion
        sudo mv /tmp/helm_completion "$COMPLETION_DIR/helm"
    fi
fi

# Install kustomize
echo "🔧 Installing kustomize..."
if command_exists kustomize; then
    echo "✅ kustomize already installed ($(kustomize version --short))"
else
    cd "$TEMP_DIR"
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    sudo mv kustomize "$BIN_DIR/"
    cd - >/dev/null
    echo "✅ kustomize installed successfully"
    
    # Add completion
    if [[ $SHELL_TYPE == "bash" ]]; then
        kustomize completion bash > /tmp/kustomize_completion
        sudo mv /tmp/kustomize_completion "$COMPLETION_DIR/kustomize"
    fi
fi

# Install kubectl-tree (show resource hierarchy)
echo "🌳 Installing kubectl-tree..."
if command_exists kubectl-tree; then
    echo "✅ kubectl-tree already installed"
else
    KUBECTL_TREE_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectl-tree/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "Installing kubectl-tree version: $KUBECTL_TREE_VERSION"
    
    # Detect architecture and OS
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    cd "$TEMP_DIR"
    curl -LO "https://github.com/ahmetb/kubectl-tree/releases/download/${KUBECTL_TREE_VERSION}/kubectl-tree_${KUBECTL_TREE_VERSION}_${OS}_${ARCH}.tar.gz"
    tar -xzf kubectl-tree_${KUBECTL_TREE_VERSION}_${OS}_${ARCH}.tar.gz
    sudo mv kubectl-tree "$BIN_DIR/"
    cd - >/dev/null
    echo "✅ kubectl-tree installed successfully"
fi

# Install dive (container image analyzer)
echo "🔍 Installing dive..."
if command_exists dive; then
    echo "✅ dive already installed"
else
    DIVE_VERSION=$(curl -s https://api.github.com/repos/wagoodman/dive/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "Installing dive version: $DIVE_VERSION"
    
    # Detect architecture and OS
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    OS=$(uname -s)
    case $OS in
        Linux) OS="linux" ;;
        Darwin) OS="darwin" ;;
        *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
    esac
    
    cd "$TEMP_DIR"
    curl -LO "https://github.com/wagoodman/dive/releases/download/${DIVE_VERSION}/dive_${DIVE_VERSION#v}_${OS}_${ARCH}.tar.gz"
    tar -xzf dive_${DIVE_VERSION#v}_${OS}_${ARCH}.tar.gz
    sudo mv dive "$BIN_DIR/"
    cd - >/dev/null
    echo "✅ dive installed successfully"
fi

echo ""
echo "🎉 Additional tools installation complete!"
echo ""
echo "📋 Installed additional tools:"
echo "   • stern (multi-pod log tailing)"
echo "   • helm (package manager)"
echo "   • kustomize (configuration management)"
echo "   • kubectl-tree (resource hierarchy)"
echo "   • dive (container image analyzer)"
echo ""
echo "🚀 Try these commands:"
echo "   stern <pod-pattern>     # tail logs from multiple pods"
echo "   helm list               # list helm releases"
echo "   kustomize build .       # build kustomized resources"
echo "   kubectl tree deploy     # show deployment hierarchy"
echo "   dive <image>            # analyze container image"
