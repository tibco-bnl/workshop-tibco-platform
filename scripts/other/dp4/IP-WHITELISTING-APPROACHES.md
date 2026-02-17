# IP Whitelisting Approaches for Kubernetes Services

## Overview
This document compares different approaches for restricting access to services in Kubernetes.

## Current Implementation

### HTTP Services (Ingress)
- **Method**: Nginx Ingress Controller annotations
- **Configuration**: `nginx.ingress.kubernetes.io/server-snippet`
- **Scope**: HTTP/HTTPS traffic only
- **Location**: Ingress resources

### TCP Services (LoadBalancer)
- **Method**: `loadBalancerSourceRanges`
- **Configuration**: Service spec field
- **Scope**: All traffic types (TCP/UDP)
- **Location**: Service resources (type: LoadBalancer)

---

## Comparison of Approaches

### 1. LoadBalancer Source Ranges (✅ Current for PostgreSQL)

**Best for**: External LoadBalancer services (TCP/UDP)

```yaml
spec:
  type: LoadBalancer
  loadBalancerSourceRanges:
  - 63.34.112.27/32
  - 10.4.0.0/16
```

**Pros**:
- ✅ Kubernetes-native (cloud-provider agnostic)
- ✅ Works at the cloud load balancer level (before traffic reaches cluster)
- ✅ Simple to configure and maintain
- ✅ Supported by all major cloud providers (Azure, AWS, GCP)
- ✅ Most efficient - blocks traffic at the network edge

**Cons**:
- ❌ Only works with LoadBalancer services
- ❌ Requires service recreation/update to change IPs

**How it works**:
1. Kubernetes configures the Azure Load Balancer
2. Azure Load Balancer drops packets from non-whitelisted IPs
3. Traffic never reaches the cluster if source IP not allowed

---

### 2. Nginx Ingress Annotations (✅ Current for HTTP Services)

**Best for**: HTTP/HTTPS services using Ingress

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      if ($remote_addr !~ "^63\.34\.112\.27$|^10\.4\.0\..*") {
        return 444;
      }
```

**Pros**:
- ✅ Works with HTTP/HTTPS protocols
- ✅ Fine-grained control (path-level, host-level)
- ✅ Can combine with other HTTP rules (auth, rate limiting)
- ✅ Supports regex patterns

**Cons**:
- ❌ Only works for HTTP/HTTPS
- ❌ Ingress controller-specific (not portable)
- ❌ Traffic reaches the cluster before being blocked

**How it works**:
1. Traffic reaches Nginx Ingress Controller pod
2. Nginx evaluates the server-snippet rule
3. Rejects connection if IP not allowed

---

### 3. Network Policy (Alternative - Not Implemented)

**Best for**: Pod-to-pod traffic control within cluster

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgresql-network-policy
  namespace: tibco-ext
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: postgresql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 63.34.112.27/32
    - ipBlock:
        cidr: 10.4.0.0/16
    ports:
    - protocol: TCP
      port: 5432
```

**Pros**:
- ✅ Kubernetes-native (standard API)
- ✅ Works for pod-to-pod and pod-to-external
- ✅ Can control egress as well as ingress
- ✅ Namespace and label-based policies
- ✅ Most flexible for complex network topologies

**Cons**:
- ❌ Requires CNI plugin support (Calico, Cilium, Azure CNI with policy)
- ❌ Not effective for external LoadBalancer traffic (IP is SNAT'd)
- ❌ More complex to troubleshoot
- ❌ Traffic still reaches the node before being blocked

**Limitation for LoadBalancer**:
When traffic comes through an Azure LoadBalancer, the source IP is often SNAT'd (Source Network Address Translation), so Network Policies see the node's IP, not the original client IP. This makes Network Policies ineffective for external LoadBalancer IP whitelisting.

---

## Recommendation

### For PostgreSQL (LoadBalancer Service)
✅ **Use `loadBalancerSourceRanges`** (Current Implementation)
- Most effective - blocks at cloud load balancer level
- Preserves original client IP
- Simple to manage
- No additional cluster resources required

### For HTTP/HTTPS Services (Ingress)
✅ **Use Nginx Ingress annotations** (Current Implementation)
- Consistent with existing infrastructure
- Allows path-level control
- Integrated with existing automation script

### When to use Network Policy
- Internal service-to-service communication restrictions
- Micro-segmentation within the cluster
- Additional defense-in-depth layer
- When you need egress control

---

## Current Whitelisted IPs

```
63.34.112.27      # External IP 1
18.200.217.204    # External IP 2
108.129.54.220    # External IP 3
62.250.248.64     # External IP 4
217.120.32.76     # External IP 5
86.90.167.198     # External IP 6
86.95.114.49      # External IP 7
10.4.0.0/16       # AKS cluster internal network
```

---

## Managing Whitelists

### For LoadBalancer (PostgreSQL)
1. Edit the service YAML file
2. Apply with `kubectl apply -f postgresql-loadbalancer.yaml`
3. Service updates automatically

### For Ingress (HTTP Services)
1. Edit the script: `scripts/other/dp4/apply-ingress-whitelist-consolidated.sh`
2. Run the script to update all ingresses at once

---

## Security Best Practices

1. **Use LoadBalancer Source Ranges** for external TCP/UDP services
2. **Use Ingress Annotations** for HTTP/HTTPS services
3. **Consider Network Policies** as an additional defense layer for internal traffic
4. **Always include cluster network** (10.4.0.0/16) in whitelists
5. **Document all IP addresses** with their purpose
6. **Review whitelists regularly** - remove unused IPs
7. **Test after changes** - verify legitimate traffic works and unauthorized traffic is blocked

---

## Verification Commands

```bash
# Check LoadBalancer service configuration
kubectl get service -n tibco-ext postgresql-external -o yaml | grep -A 10 loadBalancerSourceRanges

# Check Ingress annotations
kubectl get ingress <ingress-name> -n <namespace> -o jsonpath='{.metadata.annotations}'

# Test PostgreSQL access (should work from whitelisted IP)
psql -h postgres.mle.atsnl-emea.azure.dataplanes.pro -U postgres -d postgres

# Test from non-whitelisted IP (should timeout/fail)
# Connection will be blocked at Azure Load Balancer level
```
