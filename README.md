# Kubernetes CLI Helpers Deployment Guide

This guide provides comprehensive instructions for deploying and configuring essential Kubernetes CLI helpers to enhance your development workflow.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [kubectl Setup & Completion](#kubectl-setup--completion)
- [k9s - Kubernetes CLI Dashboard](#k9s---kubernetes-cli-dashboard)
- [kubecolor - Colorized kubectl Output](#kubecolor---colorized-kubectl-output)
- [Additional CLI Tools](#additional-cli-tools)
- [Shell Configuration](#shell-configuration)
- [Troubleshooting](#troubleshooting)

## 🔧 Prerequisites

- Linux/macOS system
- Bash or Zsh shell
- kubectl installed and configured
- Internet connection for downloading tools

## ⚙️ kubectl Setup & Completion

### Install kubectl

```bash
# Linux (x86_64)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# macOS
brew install kubectl
```

### Enable kubectl Completion

#### For Bash

```bash
# Install bash-completion if not already installed
# Ubuntu/Debian
sudo apt-get install bash-completion

# CentOS/RHEL
sudo yum install bash-completion

# Add to ~/.bashrc
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

# Reload shell
source ~/.bashrc
```

#### For Zsh

```bash
# Add to ~/.zshrc
echo 'source <(kubectl completion zsh)' >>~/.zshrc
echo 'alias k=kubectl' >>~/.zshrc
echo 'compdef __start_kubectl k' >>~/.zshrc

# Reload shell
source ~/.zshrc
```

## 🎯 k9s - Kubernetes CLI Dashboard

k9s provides a terminal-based UI for interacting with Kubernetes clusters.

### Installation

#### Using Package Managers

```bash
# macOS
brew install k9s

# Linux (Snap)
sudo snap install k9s

# Arch Linux
sudo pacman -S k9s
```

#### Manual Installation

```bash
# Download latest release
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"

# Extract and install
tar -xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
rm k9s_Linux_amd64.tar.gz
```

### Configuration

Create k9s configuration directory and customize:

```bash
mkdir -p ~/.config/k9s

# Create basic config
cat > ~/.config/k9s/config.yml << EOF
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
```

## 🌈 kubecolor - Colorized kubectl Output

kubecolor adds colors to kubectl output for better readability.

### Installation

```bash
# Download and install
KUBECOLOR_VERSION=$(curl -s https://api.github.com/repos/hidetatz/kubecolor/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO "https://github.com/hidetatz/kubecolor/releases/download/${KUBECOLOR_VERSION}/kubecolor_${KUBECOLOR_VERSION}_Linux_x86_64.tar.gz"

tar -xzf kubecolor_${KUBECOLOR_VERSION}_Linux_x86_64.tar.gz
sudo mv kubecolor /usr/local/bin/
rm kubecolor_${KUBECOLOR_VERSION}_Linux_x86_64.tar.gz
```

### Setup Alias

Add to your shell configuration:

```bash
# For Bash (~/.bashrc) or Zsh (~/.zshrc)
alias kubectl="kubecolor"
# or keep original kubectl and add colored version
alias kc="kubecolor"

# Enable completion for kubecolor
complete -o default -F __start_kubectl kubecolor  # Bash
compdef __start_kubectl kubecolor                 # Zsh
```

## 🛠️ Additional CLI Tools

### kubectx & kubens

Switch between Kubernetes contexts and namespaces easily.

```bash
# Installation
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Completion setup
mkdir -p ~/.oh-my-zsh/completions
chmod -R 755 ~/.oh-my-zsh/completions
ln -s /opt/kubectx/completion/_kubectx.zsh ~/.oh-my-zsh/completions/_kubectx.zsh
ln -s /opt/kubectx/completion/_kubens.zsh ~/.oh-my-zsh/completions/_kubens.zsh
```

### stern - Multi-pod Log Tailing

```bash
# Download and install stern
STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_${STERN_VERSION#v}_linux_amd64.tar.gz"

tar -xzf stern_${STERN_VERSION#v}_linux_amd64.tar.gz
sudo mv stern /usr/local/bin/
rm stern_${STERN_VERSION#v}_linux_amd64.tar.gz

# Add completion
stern --completion bash > /tmp/stern_completion
sudo mv /tmp/stern_completion /etc/bash_completion.d/stern
```

### helm

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add completion
helm completion bash > /tmp/helm_completion
sudo mv /tmp/helm_completion /etc/bash_completion.d/helm

# For Zsh
helm completion zsh > ~/.oh-my-zsh/completions/_helm
```

### kustomize

```bash
# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/

# Add completion
kustomize completion bash > /tmp/kustomize_completion
sudo mv /tmp/kustomize_completion /etc/bash_completion.d/kustomize
```

## 🚀 Quick Setup

### Automated Installation

Use the provided scripts in the `hack/` folder for easy setup:

```bash
# Install core tools (kubectl completion, k9s, kubecolor, kubectx/kubens)
./hack/setup-k8s-tools.sh

# Install additional tools (stern, helm, kustomize, kubectl-tree, dive)
./hack/install-additional-tools.sh

# Verify installation
./hack/verify-tools.sh
```

### Available Scripts

- **`hack/setup-k8s-tools.sh`** - Installs and configures essential Kubernetes CLI tools
- **`hack/install-additional-tools.sh`** - Installs optional but useful additional tools  
- **`hack/verify-tools.sh`** - Verifies all tools are properly installed and configured

## 🐚 Shell Configuration

The setup scripts automatically configure your shell with useful aliases:

```bash
# Core shortcuts
k          # kubectl
kc         # kubecolor  
kgp        # kubectl get pods
kgs        # kubectl get services
kgd        # kubectl get deployments
kctx       # kubectx (switch contexts)
kns        # kubens (switch namespaces)

# Additional shortcuts
kaf        # kubectl apply -f
kdel       # kubectl delete
klog       # kubectl logs
kexec      # kubectl exec -it
kinfo      # kubectl cluster-info
knodes     # kubectl get nodes
kversion   # kubectl version --short
```

## 🔍 Troubleshooting

### Common Issues

#### Completion Not Working

```bash
# Check if completion is loaded
type _kubectl >/dev/null 2>&1 && echo "kubectl completion loaded" || echo "kubectl completion NOT loaded"

# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc

# Check kubectl version
kubectl version --client
```

#### k9s Permission Issues

```bash
# Check kubeconfig permissions
ls -la ~/.kube/config

# Verify cluster connection
kubectl cluster-info
```

#### Tools Not Found in PATH

```bash
# Check if tools are in PATH
which kubectl k9s kubecolor

# Add to PATH if needed
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

### Verification Commands

```bash
# Test all tools
kubectl version --client
k9s version
kubecolor version
kubectx --help
kubens --help
stern --version
helm version
```

## 📚 Additional Resources

- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [k9s Documentation](https://k9scli.io/)
- [kubecolor GitHub](https://github.com/hidetatz/kubecolor)
- [kubectx/kubens](https://github.com/ahmetb/kubectx)
- [Kubernetes Tools Ecosystem](https://kubernetes.io/docs/tasks/tools/)
