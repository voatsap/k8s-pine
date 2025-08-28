# RKE Node Debugging Guide

This directory contains examples and commands for debugging RKE (Rancher Kubernetes Engine) nodes using `kubectl debug` with system-level access.

## 📋 Overview

When troubleshooting Kubernetes node issues, you often need direct access to the node's filesystem, processes, and logs. The `kubectl debug node` command provides a privileged debugging container with access to the host system.

## 🚀 Quick Start

### Access Node for Debugging

```bash
# Connect to a specific node with system admin privileges
kubectl debug node/10.1.7.18 -it --image=ubuntu --profile=sysadmin

# Alternative with custom image
kubectl debug node/NODE_NAME -it --image=nicolaka/netshoot --profile=sysadmin
```

The `--profile=sysadmin` gives you:
- **Root access** to the node
- **Host filesystem** mounted at `/host`
- **Host network** access
- **Privileged** container capabilities

### Enter Host Namespace

Since RKE runs as Docker containers, you'll need to access the host namespace for most debugging commands:

```bash
# Enter host namespace once (recommended approach)
chroot /host

# Now you can run commands directly without chroot prefix
docker ps
systemctl status docker
journalctl -u docker -f
```

## 🔍 RKE-Specific Debugging Commands

### RKE Process Inspection

```bash
# Find all RKE-related processes
ps aux | grep rke-

# Check RKE kubelet process
ps aux | grep kubelet

# Check RKE container runtime (cri-dockerd)
ps aux | grep cri-dockerd

# Check etcd backup process
ps aux | grep etcd-backup
```

### RKE Service Status

```bash
# First, enter host namespace
chroot /host

# RKE runs components as containers, not systemd services
# Check if systemd is available on host
systemctl --version

# Check host services (Docker/containerd)
systemctl status docker
systemctl status containerd

# Check service logs via systemd
journalctl -u docker -f
journalctl -u containerd -f

# Exit host namespace when done
exit
```

## 📊 Kubelet Debugging

### Kubelet Logs and Status

```bash
# Enter host namespace first
chroot /host

# In RKE, kubelet runs as a containerized process
# Check kubelet container
docker ps | grep kubelet

# Get kubelet logs from container
docker logs kubelet

# Follow kubelet logs in real-time
docker logs -f kubelet

# Get last 50 lines of kubelet logs
docker logs --tail 50 kubelet

# Exit host namespace
exit

# From debug container, check kubelet process details
ps aux | grep kubelet | grep -v grep

# Check kubelet configuration (RKE uses command-line args, not config.yaml)
# Enter host namespace to access kubelet container
chroot /host

# Check kubelet kubeconfig
docker exec kubelet cat /etc/kubernetes/ssl/kubecfg-kube-node.yaml

# Check kubelet command-line arguments (configuration)
docker exec kubelet ps aux | grep kubelet | grep -v grep | tr ' ' '\n' | grep -E '^--'

# Exit host namespace
exit

# Kubelet API server communication
curl -k https://localhost:10250/healthz

# Check kubelet metrics
curl -k https://localhost:10250/metrics

# Check kubelet process arguments for configuration
ps aux | grep kubelet | grep -v grep | tr ' ' '\n' | grep -E '^--'
```

### Kubelet Certificate Issues

```bash
# Check kubelet certificates
ls -la /etc/kubernetes/ssl/
openssl x509 -in /etc/kubernetes/ssl/kube-node.pem -text -noout

# Verify certificate expiration
openssl x509 -in /etc/kubernetes/ssl/kube-node.pem -noout -dates

# Check CA certificate
openssl x509 -in /etc/kubernetes/ssl/kube-ca.pem -text -noout
```

## 🐳 Container Runtime Debugging

### Docker/Containerd Status

```bash
# Enter host namespace
chroot /host

# Check Docker daemon status
systemctl status docker
docker info
docker ps -a

# Check containerd status
systemctl status containerd

# List all RKE containers
docker ps | grep -E '(rancher|hyperkube|rke)'

# Check RKE component containers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

# Exit host namespace
exit

# From debug container, check container runtime processes
ps aux | grep containerd | grep -v grep
ps aux | grep cri-dockerd
ps aux | grep containerd-shim

# Check container runtime endpoints
ls -la /var/run/cri-dockerd.sock
ls -la /run/containerd/containerd.sock
```

### Container Logs and Inspection

```bash
# Enter host namespace
chroot /host

# List all containers
docker ps -a

# Check RKE component logs
docker logs kubelet
docker logs kube-apiserver
docker logs kube-controller-manager
docker logs kube-scheduler
docker logs etcd

# Check specific container logs with timestamps
docker logs -t CONTAINER_NAME

# Follow container logs in real-time
docker logs -f CONTAINER_NAME

# Inspect container configuration
docker inspect CONTAINER_NAME

# Check container resource usage
docker stats --no-stream

# Exit host namespace
exit

# Check Kubernetes pod logs (RKE stores these in /var/log/pods/)
ls -la /var/log/pods/ | head -10

# View specific pod logs
tail -f /var/log/pods/NAMESPACE_PODNAME_UID/CONTAINER/0.log

# Example: Check system pod logs
find /var/log/pods -name '*.log' | grep kube-system | head -5

# Alternative: Find kube-system pod logs
ls /var/log/pods/ | grep kube-system | head -5
```

## 🌐 Network Debugging

### Network Interface Status

```bash
# Check network interfaces
ip addr show
ip route show

# Check CNI configuration
ls -la /etc/cni/net.d/
cat /etc/cni/net.d/*.conf

# Check iptables rules
iptables -L -n -v
iptables -t nat -L -n -v
```

### Cilium-Specific Debugging

```bash
# Check Cilium agent status (if using Cilium)
cilium status
cilium node list
cilium endpoint list

# Check Cilium connectivity
cilium connectivity test

# Cilium policy debugging
cilium policy get
cilium monitor
```

## 📁 File System and Storage

### Kubelet Directories

```bash
# Check kubelet root directory
ls -la /var/lib/kubelet/

# Pod directories
ls -la /var/lib/kubelet/pods/

# Volume mounts
ls -la /var/lib/kubelet/plugins/
ls -la /var/lib/kubelet/volumeplugins/

# Check disk usage
df -h /var/lib/kubelet/
du -sh /var/lib/kubelet/pods/*
```

### Container Storage

```bash
# Docker storage
df -h /var/lib/docker/
docker system df
docker system prune --dry-run

# Containerd storage
df -h /var/lib/containerd/
ctr --namespace k8s.io images list
```

## 🔧 System Resource Monitoring

### CPU and Memory

```bash
# System resource usage
top
htop
free -h
vmstat 1 5

# Process tree
pstree -p
ps auxf

# Check system load
uptime
cat /proc/loadavg
```

### Disk I/O and Network

```bash
# Disk I/O statistics
iostat -x 1 5
iotop

# Network statistics
netstat -tuln
ss -tuln
iftop

# Check network connections
netstat -an | grep :6443
netstat -an | grep :10250
```

## 🚨 Common Troubleshooting Scenarios

### Scenario 1: Node Not Ready

```bash
# Check node conditions
kubectl describe node NODE_NAME

# Enter host namespace
chroot /host

# Check kubelet container status
docker ps | grep kubelet
docker logs --tail 50 kubelet

# Check if all RKE containers are running
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E '(kubelet|kube-apiserver|kube-controller|kube-scheduler|etcd)'

# Check Docker daemon status
systemctl status docker

# Exit host namespace
exit

# Check if kubelet process is accessible
ps aux | grep kubelet | grep -v grep

# Check if kubelet can reach API server
curl -k https://API_SERVER_IP:6443/healthz

# Verify certificates
openssl x509 -in /etc/kubernetes/ssl/kube-node.pem -noout -dates

# Check container runtime processes
ps aux | grep cri-dockerd
```

### Scenario 2: Pods Stuck in Pending

```bash
# Check node resources
kubectl describe node NODE_NAME
free -h
df -h

# Enter host namespace
chroot /host

# Check container runtime status
docker info
docker ps > /dev/null && echo 'Docker responding' || echo 'Docker not responding'

# Check kubelet container logs for scheduling issues
docker logs --tail 100 kubelet | grep -i "failed\|error\|insufficient"

# Check disk space for container storage
df -h /var/lib/docker/
df -h /var/lib/containerd/

# Check if kubelet container is healthy
docker inspect kubelet | grep -A5 "Health"

# Exit host namespace
exit

# Check container runtime processes
ps aux | grep cri-dockerd
```

### Scenario 3: Network Connectivity Issues

```bash
# Test DNS resolution
nslookup kubernetes.default.svc.cluster.local
dig @10.9.0.10 kubernetes.default.svc.cluster.local

# Check CNI plugin
ls -la /opt/cni/bin/
cat /etc/cni/net.d/*.conf

# Test pod-to-pod connectivity
ping POD_IP
traceroute POD_IP
```

### Scenario 4: Certificate Expiration

```bash
# Check all certificates
find /etc/kubernetes/ssl/ -name "*.pem" -exec openssl x509 -in {} -noout -subject -dates \;

# Check API server certificate
echo | openssl s_client -connect API_SERVER_IP:6443 2>/dev/null | openssl x509 -noout -dates

# Renew certificates (RKE specific)
# This typically requires RKE cluster configuration update
```

## 📊 Log Collection for Support

### Comprehensive Log Collection

```bash
# Create log collection directory
mkdir -p /tmp/node-debug-$(date +%Y%m%d-%H%M%S)
cd /tmp/node-debug-*

# Collect system information
uname -a > system-info.txt
cat /etc/os-release >> system-info.txt
uptime >> system-info.txt
free -h >> system-info.txt
df -h >> system-info.txt

# Enter host namespace for container logs
chroot /host bash << 'EOF'
# Collect all RKE container logs
docker logs kubelet > /tmp/kubelet.log 2>&1
docker logs kube-apiserver > /tmp/kube-apiserver.log 2>&1
docker logs kube-controller-manager > /tmp/kube-controller-manager.log 2>&1
docker logs kube-scheduler > /tmp/kube-scheduler.log 2>&1
docker logs etcd > /tmp/etcd.log 2>&1

# Collect container runtime logs from systemd
journalctl -u docker --since "24 hours ago" > /tmp/docker.log 2>/dev/null
journalctl -u containerd --since "24 hours ago" > /tmp/containerd.log 2>/dev/null

# Collect container information
docker ps -a > /tmp/containers.txt
docker images > /tmp/images.txt
EOF

# Copy logs from host
cp /host/tmp/*.log .

# Collect RKE process information
ps aux | grep -E '(kubelet|rke|cri-dockerd)' > rke-processes.txt

# Collect Kubernetes pod logs
tar -czf pod-logs.tar.gz -C /var/log/pods . 2>/dev/null || echo 'No pod logs collected'

# Collect network information
ip addr show > network-interfaces.txt
ip route show > network-routes.txt
iptables -L -n -v > iptables-filter.txt
iptables -t nat -L -n -v > iptables-nat.txt

# Collect process information
ps auxf > processes.txt
pstree -p > process-tree.txt

# Create archive
tar -czf node-debug-$(hostname)-$(date +%Y%m%d-%H%M%S).tar.gz *
```

## 🛠️ Advanced Debugging Tools

### Install Additional Tools

```bash
# Update package manager
apt update

# Install network debugging tools
apt install -y tcpdump wireshark-common netcat-openbsd

# Install system debugging tools
apt install -y strace ltrace sysstat

# Install container debugging tools
apt install -y skopeo buildah
```

### Network Packet Capture

```bash
# Capture packets on specific interface
tcpdump -i eth0 -w /tmp/network-capture.pcap

# Capture API server traffic
tcpdump -i any port 6443 -w /tmp/apiserver-traffic.pcap

# Capture kubelet traffic
tcpdump -i any port 10250 -w /tmp/kubelet-traffic.pcap
```

### Process Tracing

```bash
# Trace system calls for kubelet
strace -p $(pgrep kubelet) -o /tmp/kubelet-strace.log

# Trace file operations
strace -e trace=file -p $(pgrep kubelet)

# Monitor file access
inotifywait -m -r /var/lib/kubelet/
```

## 🔐 Security Considerations

### Audit and Compliance

```bash
# Check file permissions
find /etc/kubernetes/ssl/ -ls
find /var/lib/kubelet/ -type f -perm /o+r

# Check running processes as root
ps aux | awk '$1 == "root"'

# Check network listening services
netstat -tuln | grep LISTEN
```

### Clean Up After Debugging

```bash
# Remove debugging containers
kubectl get pods --all-namespaces | grep debug
kubectl delete pod DEBUG_POD_NAME

# Clean up temporary files
rm -rf /tmp/node-debug-*
rm -f /tmp/*.pcap /tmp/*.log
```

## 📚 Useful Commands Reference

### Quick Health Checks

```bash
# One-liner system health check (enter host namespace first)
chroot /host bash -c "
echo '=== System Info ===' && uname -a && \
echo '=== Load ===' && uptime && \
echo '=== Memory ===' && free -h && \
echo '=== Disk ===' && df -h && \
echo '=== Kubelet Container ===' && docker ps | grep kubelet && \
echo '=== Docker Status ===' && systemctl is-active docker
"
```

### Log Monitoring

```bash
# Monitor multiple logs simultaneously (enter host namespace first)
chroot /host

# Monitor container logs in real-time
docker logs -f kubelet &
docker logs -f kube-apiserver &
docker logs -f etcd &

# Monitor system logs
tail -f /var/log/syslog &
journalctl -u docker -f &

# Exit host namespace when done
exit
```

## ⚠️ Important Notes

- **Privileged Access**: The `--profile=sysadmin` provides full root access to the node
- **Host Filesystem**: Access host files via `/host` prefix when needed
- **Resource Impact**: Debugging tools can consume system resources
- **Security**: Always clean up debugging containers and temporary files
- **Documentation**: Keep detailed notes of issues and solutions found

## 🎯 Quick Troubleshooting Checklist

```bash
# Essential checks when debugging RKE nodes

# Enter host namespace once
chroot /host

□ docker ps | grep -E '(kubelet|kube-apiserver|etcd)'
□ docker logs --tail 20 kubelet
□ systemctl status docker
□ docker info
□ df -h /var/lib/docker/

# Exit host namespace
exit

□ ps aux | grep cri-dockerd
□ free -h
□ ls -la /var/log/pods/ | head -10
□ netstat -tuln | grep -E "(6443|10250|2379)"
□ openssl x509 -in /etc/kubernetes/ssl/kube-node.pem -noout -dates
□ curl -k https://localhost:10250/healthz
```

This guide provides comprehensive debugging capabilities for RKE nodes. Always start with basic checks before moving to advanced debugging techniques.
