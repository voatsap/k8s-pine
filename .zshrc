
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/voa/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/voa/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/voa/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/voa/google-cloud-sdk/completion.zsh.inc'; fi
source <(kubectl completion zsh)
alias kc="kubecolor"
compdef _kubectl kubecolor

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
alias kversion="kubkubecolorectl version --short"

alias k=kubecolor
compdef _kubectl k

