#!/bin/bash
# Kubernetes CLI Tools Setup Script
# This script installs and configures essential Kubernetes CLI helpers

set -e

echo "🚀 Setting up Kubernetes CLI tools..."

# Function to detect shell
detect_shell() {
    if [[ $SHELL == *"zsh"* ]]; then
        echo "zsh"
    else
        echo "bash"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Configuration variables
BIN_DIR="/usr/local/bin"
OPT_DIR="/opt"
K9S_CONFIG_DIR="$HOME/.config/k9s"
TEMP_DIR=$(mktemp -d)

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

SHELL_TYPE=$(detect_shell)
echo "Detected shell: $SHELL_TYPE"

# Setup kubectl completion
echo "⚙️ Setting up kubectl completion..."
if ! command_exists kubectl; then
    echo "❌ kubectl not found. Please install kubectl first."
    echo "Installation instructions: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    exit 1
fi

if [[ $SHELL_TYPE == "zsh" ]]; then
    if ! grep -q "kubectl completion zsh" ~/.zshrc 2>/dev/null; then
        echo 'source <(kubectl completion zsh)' >> ~/.zshrc
        echo 'alias k=kubecolor' >> ~/.zshrc
        echo 'compdef _kubectl k' >> ~/.zshrc
        echo "✅ kubectl completion added to ~/.zshrc"
    else
        echo "✅ kubectl completion already configured"
    fi
else
    if ! grep -q "kubectl completion bash" ~/.bashrc 2>/dev/null; then
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        echo 'alias k=kubecolor' >> ~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
        echo "✅ kubectl completion added to ~/.bashrc"
    else
        echo "✅ kubectl completion already configured"
    fi
fi

# Install k9s
echo "🎯 Installing k9s..."
if command_exists k9s; then
    echo "✅ k9s already installed ($(k9s version 2>/dev/null | head -1 || echo 'version unknown'))"
else
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "Installing k9s version: $K9S_VERSION"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Detect OS
    OS=$(uname -s)
    case $OS in
        Linux) OS="Linux" ;;
        Darwin) OS="Darwin" ;;
        *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
    esac
    
    cd "$TEMP_DIR"
    curl -LO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_${OS}_${ARCH}.tar.gz"
    tar -xzf k9s_${OS}_${ARCH}.tar.gz
    sudo mv k9s "$BIN_DIR/"
    cd - >/dev/null
    echo "✅ k9s installed successfully"
fi

# Create k9s config directory
mkdir -p "$K9S_CONFIG_DIR"
if [[ ! -f "$K9S_CONFIG_DIR/config.yml" ]]; then
    cat > "$K9S_CONFIG_DIR/config.yml" << 'EOF'
k9s:
  refreshRate: 2
  maxConnRetry: 5
  readOnly: false
  noExitOnCtrlC: false
  ui:
    enableMouse: false
    headless: false
    logoless: false
    crumbsless: false
    reactive: false
    noIcons: false
  skipLatestRevCheck: false
  disablePodCounting: false
  shellPod:
    image: busybox:1.35.0
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
  imageScans:
    enable: false
    exclusions:
      namespaces: []
      labels: {}
  logger:
    tail: 100
    buffer: 5000
    sinceSeconds: -1
    textWrap: false
    showTime: false
EOF
    echo "✅ k9s configuration created"
fi

# Install kubecolor
echo "🌈 Installing kubecolor..."
if command_exists kubecolor; then
    echo "✅ kubecolor already installed ($(kubecolor version 2>/dev/null || echo 'version unknown'))"
else
    echo "Installing kubecolor via go install (most reliable method)..."
    if command_exists go; then
        go install github.com/kubecolor/kubecolor@latest
        # Ensure go/bin is in PATH and create symlink for system-wide access
        GOPATH=$(go env GOPATH)
        if [[ -f "$GOPATH/bin/kubecolor" ]]; then
            sudo ln -sf "$GOPATH/bin/kubecolor" "$BIN_DIR/kubecolor"
            echo "✅ kubecolor installed successfully via go and linked to $BIN_DIR"
        else
            echo "⚠️ kubecolor installed via go but not found in expected location"
        fi
    else
        echo "⚠️ Go not found. Installing kubecolor binary..."
        # Fallback to binary installation
        KUBECOLOR_VERSION=$(curl -s https://api.github.com/repos/kubecolor/kubecolor/releases/latest | grep tag_name | cut -d '"' -f 4 2>/dev/null || echo "v0.3.3")
        echo "Installing kubecolor version: $KUBECOLOR_VERSION"
        
        # Use simplified download for common case
        if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
            cd "$TEMP_DIR"
            curl -LO "https://github.com/kubecolor/kubecolor/releases/download/${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION}_linux_x86_64.tar.gz" 2>/dev/null || {
                echo "⚠️ Binary download failed. You can install kubecolor manually with:"
                echo "   go install github.com/kubecolor/kubecolor@latest"
                echo "Continuing with other tools..."
                cd - >/dev/null
                return 0
            }
            tar -xzf kubecolor_${KUBECOLOR_VERSION}_linux_x86_64.tar.gz 2>/dev/null || {
                echo "⚠️ Failed to extract kubecolor. Skipping..."
                cd - >/dev/null
                return 0
            }
            sudo mv kubecolor "$BIN_DIR/" 2>/dev/null && {
                echo "✅ kubecolor installed successfully"
            } || {
                echo "⚠️ Failed to install kubecolor binary. Install manually with go install."
            }
            cd - >/dev/null
        else
            echo "⚠️ Automated binary install only supports Linux x86_64. Install manually with:"
            echo "   go install github.com/kubecolor/kubecolor@latest"
        fi
    fi
fi

# Setup kubecolor alias
if [[ $SHELL_TYPE == "zsh" ]]; then
    if ! grep -q 'alias kc="kubecolor"' ~/.zshrc 2>/dev/null; then
        echo 'alias kc="kubecolor"' >> ~/.zshrc
        echo 'compdef __start_kubectl kubecolor' >> ~/.zshrc
        echo "✅ kubecolor aliases added to ~/.zshrc"
    fi
else
    if ! grep -q 'alias kc="kubecolor"' ~/.bashrc 2>/dev/null; then
        echo 'alias kc="kubecolor"' >> ~/.bashrc
        echo 'complete -o default -F __start_kubectl kubecolor' >> ~/.bashrc
        echo "✅ kubecolor aliases added to ~/.bashrc"
    fi
fi

# Install kubectx and kubens
echo "🔄 Installing kubectx and kubens..."
if command_exists kubectx && command_exists kubens; then
    echo "✅ kubectx and kubens already installed"
else
    KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "Installing kubectx and kubens version: $KUBECTX_VERSION"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="x86_64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        armv7*) ARCH="armv7" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $OS in
        linux) OS="linux" ;;
        darwin) OS="darwin" ;;
        *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
    esac
    
    # Download and install kubectx
    if ! command_exists kubectx; then
        echo "📦 Installing kubectx..."
        cd "$TEMP_DIR"
        curl -LO "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_${OS}_${ARCH}.tar.gz"
        tar -xzf kubectx_${KUBECTX_VERSION}_${OS}_${ARCH}.tar.gz
        sudo mv kubectx "$BIN_DIR/"
        cd - >/dev/null
        echo "✅ kubectx installed successfully"
    fi
    
    # Download and install kubens
    if ! command_exists kubens; then
        echo "📦 Installing kubens..."
        cd "$TEMP_DIR"
        curl -LO "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_${OS}_${ARCH}.tar.gz"
        tar -xzf kubens_${KUBECTX_VERSION}_${OS}_${ARCH}.tar.gz
        sudo mv kubens "$BIN_DIR/"
        cd - >/dev/null
        echo "✅ kubens installed successfully"
    fi
    
    # Setup completion (download completion files separately)
    if [[ $SHELL_TYPE == "zsh" ]]; then
        echo "📋 Setting up zsh completion..."
        mkdir -p ~/.oh-my-zsh/completions 2>/dev/null || true
        
        # Download completion files
        curl -sL "https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/_kubectx.zsh" -o ~/.oh-my-zsh/completions/_kubectx.zsh 2>/dev/null || true
        curl -sL "https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/_kubens.zsh" -o ~/.oh-my-zsh/completions/_kubens.zsh 2>/dev/null || true
        echo "✅ zsh completion configured"
    fi
fi

# Add useful aliases
echo "🔗 Adding useful Kubernetes aliases..."
ALIASES='
# Kubernetes shortcuts
alias k="kubecolor"
alias kgp="kubecolor get pods"
alias kgs="kubecolor get services"
alias kgd="kubecolor get deployments"
alias kaf="kubecolor apply -f"
alias kdel="kubecolor delete"
alias klog="kubecolor logs"
alias kexec="kubecolor exec -it"
alias kctx="kubectx"
alias kns="kubens"

# kubecolor variants
alias kcgp="kubecolor get pods"
alias kcgs="kubecolor get services"
alias kcgd="kubecolor get deployments"

# Quick cluster info
alias kinfo="kubecolor cluster-info"
alias knodes="kubecolor get nodes"
alias kversion="kubecolor version --short"
'

if [[ $SHELL_TYPE == "zsh" ]]; then
    if ! grep -q "# Kubernetes shortcuts" ~/.zshrc 2>/dev/null; then
        echo "$ALIASES" >> ~/.zshrc
        echo "✅ Kubernetes aliases added to ~/.zshrc"
    fi
else
    if ! grep -q "# Kubernetes shortcuts" ~/.bashrc 2>/dev/null; then
        echo "$ALIASES" >> ~/.bashrc
        echo "✅ Kubernetes aliases added to ~/.bashrc"
    fi
fi

echo ""
echo "🎉 Setup complete! Please restart your shell or run:"
if [[ $SHELL_TYPE == "zsh" ]]; then
    echo "   source ~/.zshrc"
else
    echo "   source ~/.bashrc"
fi
echo ""
echo "📋 Installed tools:"
echo "   • kubectl (with completion)"
echo "   • k9s (Kubernetes dashboard)"
echo "   • kubecolor (colorized kubectl)"
echo "   • kubectx/kubens (context/namespace switching)"
echo "   • Useful aliases and shortcuts"
echo ""
echo "🚀 Try these commands:"
echo "   k get pods          # kubectl with alias"
echo "   kc get pods         # colorized output"
echo "   k9s                 # launch dashboard"
echo "   kctx                # list contexts"
echo "   kns                 # list namespaces"
