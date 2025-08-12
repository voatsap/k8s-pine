
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/voa/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/voa/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/voa/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/voa/google-cloud-sdk/completion.zsh.inc'; fi
source <(kubectl completion zsh)
alias kc="kubecolor"
compdef _kubectl kubecolor

# Kubernetes shortcuts
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kaf="kubectl apply -f"
alias kdel="kubectl delete"
alias klog="kubectl logs"
alias kexec="kubectl exec -it"
alias kctx="kubectx"
alias kns="kubens"

# kubecolor variants
alias kcgp="kubecolor get pods"
alias kcgs="kubecolor get services"
alias kcgd="kubecolor get deployments"

# Quick cluster info
alias kinfo="kubectl cluster-info"
alias knodes="kubectl get nodes"
alias kversion="kubectl version --short"

alias k=kubecolor
compdef _kubectl k

