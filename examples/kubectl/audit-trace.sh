#!/bin/bash
# audit-trace.sh - Trace Kubernetes operations

set -e

echo "=== KUBERNETES OPERATION TRACER ==="
echo "Monitoring events and operations..."

# Function to trace pod creation
trace_pod_creation() {
    local pod_name=$1
    echo "Tracing creation of pod: $pod_name"
    
    # Start event monitoring in background
    kubectl get events --watch --field-selector involvedObject.name=$pod_name &
    EVENTS_PID=$!
    
    # Create the pod
    kubectl run $pod_name --image=nginx --restart=Never --v=6
    
    # Wait a moment for events
    sleep 5
    
    # Stop event monitoring
    kill $EVENTS_PID 2>/dev/null || true
    
    # Show final status
    echo "=== FINAL POD STATUS ==="
    kubectl get pod $pod_name -o wide
    
    echo "=== ALL EVENTS FOR POD ==="
    kubectl get events --field-selector involvedObject.name=$pod_name --sort-by=.metadata.creationTimestamp
}

# Function to debug pod creation failures
debug_pod_creation() {
    local pod_name=$1
    
    echo "=== POD STATUS ==="
    kubectl get pod $pod_name -o wide
    
    echo "=== POD EVENTS ==="
    kubectl get events --field-selector involvedObject.name=$pod_name
    
    echo "=== POD DESCRIPTION ==="
    kubectl describe pod $pod_name
    
    echo "=== NODE EVENTS (if scheduled) ==="
    local node=$(kubectl get pod $pod_name -o jsonpath='{.spec.nodeName}' 2>/dev/null)
    if [[ -n "$node" ]]; then
        kubectl get events --field-selector involvedObject.name=$node | tail -10
    fi
}

# Function to monitor security events
monitor_security_events() {
    echo "=== MONITORING SECURITY EVENTS ==="
    echo "Press Ctrl+C to stop monitoring"
    
    kubectl get events --all-namespaces --watch | grep -E "(Forbidden|Unauthorized|Failed|Error)"
}

# Function to analyze audit patterns
analyze_audit_patterns() {
    echo "=== AUDIT PATTERN ANALYSIS ==="
    
    echo "Recent pod creation events:"
    kubectl get events --all-namespaces | grep "Created pod" | tail -10
    
    echo -e "\nFailed operations:"
    kubectl get events --all-namespaces | grep -E "(Failed|Error)" | tail -10
    
    echo -e "\nRBAC denials:"
    kubectl get events --all-namespaces | grep "Forbidden" | tail -10
    
    echo -e "\nResource creation patterns:"
    kubectl get events --all-namespaces | grep "Created" | awk '{print $6}' | sort | uniq -c
}

# Main script logic
case "${1:-help}" in
    "trace")
        if [[ -n "$2" ]]; then
            trace_pod_creation "$2"
        else
            trace_pod_creation "traced-pod-$(date +%s)"
        fi
        ;;
    "debug")
        if [[ -n "$2" ]]; then
            debug_pod_creation "$2"
        else
            echo "Usage: $0 debug <pod-name>"
            exit 1
        fi
        ;;
    "monitor")
        monitor_security_events
        ;;
    "analyze")
        analyze_audit_patterns
        ;;
    "help"|*)
        echo "Usage: $0 {trace|debug|monitor|analyze} [pod-name]"
        echo ""
        echo "Commands:"
        echo "  trace [pod-name]  - Trace creation of a new pod (creates pod if name not provided)"
        echo "  debug <pod-name>  - Debug an existing pod's creation issues"
        echo "  monitor           - Monitor security events in real-time"
        echo "  analyze           - Analyze recent audit patterns"
        echo ""
        echo "Examples:"
        echo "  $0 trace my-test-pod"
        echo "  $0 debug problematic-pod"
        echo "  $0 monitor"
        echo "  $0 analyze"
        ;;
esac
