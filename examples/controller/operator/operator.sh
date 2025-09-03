#!/bin/sh
set -eu

log() { echo "[operator] $*"; }

log "Starting ConfigWatcher operator..."

# Function to restart workloads for a given ConfigWatcher
restart_workloads() {
  local ns="$1"
  local name="$2"
  local configmap="$3"
  local selector="$4"
  
  log "Processing ConfigWatcher ${ns}/${name}: configmap=${configmap}, selector=${selector}"
  
  # Get the ConfigMap's resource version
  if ! last_update=$(kubectl -n "$ns" get cm "$configmap" -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null); then
    log "ConfigMap ${ns}/${configmap} not found"
    kubectl -n "$ns" patch configwatcher "$name" --type merge -p "{\"status\":{\"lastUpdate\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"message\":\"ConfigMap ${configmap} not found\"}}" 2>/dev/null || true
    return
  fi
  
  # Update the ConfigWatcher status
  kubectl -n "$ns" patch configwatcher "$name" --type merge -p "{\"status\":{\"lastUpdate\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"message\":\"ConfigMap ${configmap} changed (rv: ${last_update}), restarting workloads\"}}" 2>/dev/null || true
  
  # Restart deployments matching the selector
  if kubectl -n "$ns" get deploy -l "$selector" -o name >/dev/null 2>&1; then
    log "Rolling restart deployments (-n $ns -l $selector)"
    kubectl -n "$ns" rollout restart deploy -l "$selector" || log "Failed to restart deployments"
  fi
  
  # Also restart pods directly (in case there are standalone pods)
  if kubectl -n "$ns" get pod -l "$selector" -o name >/dev/null 2>&1; then
    log "Deleting pods for immediate restart (-n $ns -l $selector)"
    kubectl -n "$ns" delete pod -l "$selector" --ignore-not-found || log "Failed to delete pods"
  fi
}

# Function to process all ConfigWatchers for a changed ConfigMap
process_configmap_change() {
  local ns="$1"
  local configmap="$2"
  
  log "ConfigMap ${ns}/${configmap} changed, checking for ConfigWatchers..."
  
  # Find all ConfigWatchers that reference this ConfigMap (using kubectl jsonpath)
  kubectl get configwatchers -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CONFIGMAP:.spec.configMap,SELECTOR:.spec.selector --no-headers | while read -r cw_ns cw_name cw_configmap cw_selector; do
    if [ -z "${cw_ns:-}" ] || [ -z "${cw_name:-}" ] || [ -z "${cw_configmap:-}" ] || [ -z "${cw_selector:-}" ]; then
      continue
    fi
    
    # Check if this ConfigWatcher references the changed ConfigMap
    if [ "$cw_ns" = "$ns" ] && [ "$cw_configmap" = "$configmap" ]; then
      restart_workloads "$cw_ns" "$cw_name" "$cw_configmap" "$cw_selector"
    fi
  done
}

# Watch for ConfigMap changes across all namespaces
log "Watching for ConfigMap changes..."
kubectl get configmaps -A --watch -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,RESOURCE_VERSION:.metadata.resourceVersion --no-headers | while read -r ns name rv; do
  if [ -z "${ns:-}" ] || [ -z "${name:-}" ] || [ -z "${rv:-}" ]; then
    continue
  fi
  
  # Skip system ConfigMaps
  case "$name" in
    kube-*|coredns|extension-apiserver-authentication|*-ca-bundle)
      continue
      ;;
  esac
  
  log "ConfigMap change detected: ${ns}/${name} (rv: ${rv})"
  process_configmap_change "$ns" "$name"
done
