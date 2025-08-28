# Kubernetes Cluster Audit Log Debugging

Quick commands for analyzing Kubernetes audit logs to investigate security events, access patterns, and troubleshoot cluster issues.

## 🔍 Audit Overview

Kubernetes auditing provides chronological records of cluster activities to answer:
- **What happened?** - Actions performed
- **When?** - Timestamps of events  
- **Who?** - Users/service accounts
- **Where?** - Resources affected
- **How?** - Request details and responses

## 📋 Audit Configuration Check

### Verify Audit is Enabled
```bash
# Check if audit is configured on API server
kubectl debug node/NODE_NAME -it --image=ubuntu --profile=sysadmin
chroot /host

# Check kube-apiserver audit flags
docker exec kube-apiserver ps aux | grep audit

# View audit configuration
docker exec kube-apiserver cat /proc/1/cmdline | tr '\0' '\n' | grep audit

exit
```

### RKE Audit Configuration
```bash
# RKE audit settings (from node debug)
chroot /host

# Audit policy location
docker exec kube-apiserver cat /etc/kubernetes/audit-policy.yaml

# Audit log location  
ls -la /var/log/kube-audit/

# Current audit log
tail -10 /var/log/kube-audit/audit-log.json

exit
```

## 📊 Basic Audit Log Analysis

### Recent Activity
```bash
# Enter node to access audit logs
kubectl debug node/NODE_NAME -it --image=ubuntu --profile=sysadmin
chroot /host

# Latest audit events
tail -20 /var/log/kube-audit/audit-log.json | jq .

# Events from last hour
find /var/log/kube-audit/ -name "*.json" -newermt "1 hour ago" -exec cat {} \; | jq .

# Count events by hour
ls -la /var/log/kube-audit/ | grep $(date +%Y-%m-%d)
```

### Event Filtering
```bash
# Failed authentication attempts
cat /var/log/kube-audit/audit-log.json | jq 'select(.verb == "create" and .responseStatus.code >= 400)'

# Privileged operations
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username == "system:admin" or .user.groups[]? == "system:masters")'

# Resource deletions
cat /var/log/kube-audit/audit-log.json | jq 'select(.verb == "delete")'

# Specific user activity
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username == "USERNAME")'
```

## 🔐 Security Analysis

### Authentication Events
```bash
# Failed logins
cat /var/log/kube-audit/audit-log.json | jq 'select(.responseStatus.code == 401)'

# Anonymous access attempts
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username == "system:anonymous")'

# Service account usage
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username | startswith("system:serviceaccount"))'

# External user access
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username | startswith("system:") | not)'
```

### Authorization Events
```bash
# RBAC denials (403 errors)
cat /var/log/kube-audit/audit-log.json | jq 'select(.responseStatus.code == 403)'

# Privilege escalation attempts
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.resource == "clusterrolebindings" or .objectRef.resource == "rolebindings")'

# Admin operations
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.groups[]? == "system:masters")'
```

### Resource Access Patterns
```bash
# Secret access
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.resource == "secrets")'

# ConfigMap modifications
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.resource == "configmaps" and .verb != "get")'

# Pod exec/attach operations
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.subresource == "exec" or .objectRef.subresource == "attach")'
```

## 🕵️ Troubleshooting with Audit Logs

### API Server Issues
```bash
# High latency requests (show requests with different timestamps)
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.stageTimestamp and .requestReceivedTimestamp and .stageTimestamp != .requestReceivedTimestamp) | "\(.requestReceivedTimestamp) \(.stageTimestamp) \(.verb) \(.objectRef.resource // "unknown")"'

# Large request/response bodies
cat /var/log/kube-audit/audit-log.json | jq 'select(.requestObject or .responseObject)'

# Error responses
cat /var/log/kube-audit/audit-log.json | jq 'select(.responseStatus.code >= 400)'
```

### Resource Management
```bash
# Resource creation failures
cat /var/log/kube-audit/audit-log.json | jq 'select(.verb == "create" and .responseStatus.code >= 400)'

# Quota violations
cat /var/log/kube-audit/audit-log.json | jq 'select(.responseStatus.reason == "Forbidden" and (.responseStatus.message | contains("quota")))'

# Admission controller rejections
cat /var/log/kube-audit/audit-log.json | jq 'select(.responseStatus.code == 400 and (.responseStatus.message | contains("admission")))'
```

### Network Policy Analysis
```bash
# NetworkPolicy changes
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.resource == "networkpolicies")'

# Service modifications
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.resource == "services" and .verb != "get")'
```

## 📈 Audit Log Statistics

### Activity Summary
```bash
# Top users by request count
cat /var/log/kube-audit/audit-log.json | jq -r '.user.username' | sort | uniq -c | sort -nr | head -10

# Top resources accessed
cat /var/log/kube-audit/audit-log.json | jq -r '.objectRef.resource' | sort | uniq -c | sort -nr | head -10

# HTTP status code distribution
cat /var/log/kube-audit/audit-log.json | jq -r '.responseStatus.code' | sort | uniq -c | sort -nr

# Verb distribution
cat /var/log/kube-audit/audit-log.json | jq -r '.verb' | sort | uniq -c | sort -nr
```

### Time-based Analysis
```bash
# Events per hour (last 24h)
for hour in {0..23}; do
  count=$(cat /var/log/kube-audit/audit-log.json | jq -r --arg h "$hour" 'select(.requestReceivedTimestamp | strftime("%H") == $h)' | wc -l)
  echo "Hour $hour: $count events"
done

# Peak activity detection
cat /var/log/kube-audit/audit-log.json | jq -r '.requestReceivedTimestamp | strftime("%Y-%m-%d %H")' | sort | uniq -c | sort -nr | head -5
```

## 🔧 Advanced Analysis

### Custom Queries
```bash
# Namespace-specific activity
cat /var/log/kube-audit/audit-log.json | jq 'select(.objectRef.namespace == "NAMESPACE")'

# Cross-namespace access
cat /var/log/kube-audit/audit-log.json | jq 'select(.user.username | startswith("system:serviceaccount:") and (.objectRef.namespace != (.user.username | split(":")[2])))'

# External traffic analysis
cat /var/log/kube-audit/audit-log.json | jq 'select(.sourceIPs[]? | startswith("10.") or startswith("192.168.") or startswith("172.") | not)'
```

### Performance Analysis
```bash
# Slowest operations by resource type (show requests with timing differences)
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.stageTimestamp and .requestReceivedTimestamp and .stageTimestamp != .requestReceivedTimestamp) | "\(.objectRef.resource // "unknown") \(.requestReceivedTimestamp) \(.stageTimestamp) \(.verb)"' | head -10

# Request size analysis
cat /var/log/kube-audit/audit-log.json | jq 'select(.requestObject) | {resource: .objectRef.resource, size: (.requestObject | tostring | length)}'
```

## 📋 Audit Log Maintenance

### Log Rotation Status
```bash
# Check current log files
ls -lah /var/log/kube-audit/

# Disk usage
du -sh /var/log/kube-audit/

# Log rotation configuration (from API server flags)
docker exec kube-apiserver ps aux | grep -E "audit-log-max(age|backup|size)"
```

### Log Cleanup
```bash
# Find old audit logs (older than 30 days)
find /var/log/kube-audit/ -name "*.json" -mtime +30

# Archive old logs
tar -czf audit-archive-$(date +%Y%m%d).tar.gz /var/log/kube-audit/*.json -not -name "audit-log.json"
```

## 🎯 Quick Investigation Scripts

### Security Incident Response
```bash
#!/bin/bash
# Quick security check script
echo "=== Failed Authentication ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.responseStatus.code == 401) | "\(.requestReceivedTimestamp) \(.user.username) \(.sourceIPs[0])"' | tail -10

echo "=== Privilege Escalation (Actual Modifications) ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.objectRef.resource == "clusterrolebindings" and (.verb == "create" or .verb == "update" or .verb == "patch") and (.user.username | startswith("system:") | not)) | "\(.requestReceivedTimestamp) \(.user.username) \(.verb) \(.objectRef.name // "unknown")"' | tail -5

echo "=== RoleBinding Modifications ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.objectRef.resource == "rolebindings" and (.verb == "create" or .verb == "update" or .verb == "patch") and (.user.username | startswith("system:") | not)) | "\(.requestReceivedTimestamp) \(.user.username) \(.verb) \(.objectRef.namespace)/\(.objectRef.name // "unknown")"' | tail -5

echo "=== Secret Access ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.objectRef.resource == "secrets" and .verb != "get") | "\(.requestReceivedTimestamp) \(.user.username) \(.verb) \(.objectRef.namespace)/\(.objectRef.name)"' | tail -5
```

### Performance Investigation
```bash
#!/bin/bash
# Performance analysis script
echo "=== Requests with Processing Time ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.stageTimestamp and .requestReceivedTimestamp and .stageTimestamp != .requestReceivedTimestamp) | "\(.requestReceivedTimestamp) \(.verb) \(.objectRef.resource // "unknown") \(.stageTimestamp)"' | tail -10

echo "=== Error Rate by Hour ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.responseStatus.code >= 400) | .requestReceivedTimestamp[0:13]' | sort | uniq -c

echo "=== Top Error-Generating Users ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.responseStatus.code >= 400) | .user.username' | sort | uniq -c | sort -nr | head -5

echo "=== Most Common Error Types ==="
cat /var/log/kube-audit/audit-log.json | jq -r 'select(.responseStatus.code >= 400) | "\(.responseStatus.code) \(.responseStatus.reason // "unknown")"' | sort | uniq -c | sort -nr | head -5
```