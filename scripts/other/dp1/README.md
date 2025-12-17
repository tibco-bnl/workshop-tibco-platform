# IP Whitelist Configuration for Ingress Endpoints (DP1 Cluster)

This directory contains scripts to manage IP-based access control for UI-related ingress endpoints in the dp1-aks-aauk-kul cluster.

## Overview

This cluster uses the `nginx.ingress.kubernetes.io/whitelist-source-range` annotation for IP whitelisting (snippet directives are disabled by the ingress administrator for security). The script retrieves the IP whitelist configuration from the Kibana ingress (which serves as the source of truth) and applies it to all other UI ingress endpoints.

## Protected Endpoints

The following endpoints are protected with IP whitelist:

- `apm.dp1.kul.atsnl-emea.azure.dataplanes.pro`
- `elastic.dp1.kul.atsnl-emea.azure.dataplanes.pro`
- `kibana.dp1.kul.atsnl-emea.azure.dataplanes.pro`
- `grafana.dp1.kul.atsnl-emea.azure.dataplanes.pro`
- `prometheus-internal.dp1.kul.atsnl-emea.azure.dataplanes.pro`

## How to View Current Whitelisted IPs

To see the current whitelisted IP addresses:

```bash
kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range}'
```

## How to Add Your IP Address

### Step 1: Find Your Public IP Address

```bash
curl -s -4 ifconfig.me
```

### Step 2: Get Current Whitelist

```bash
CURRENT_WHITELIST=$(kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range}')
echo "Current whitelist: $CURRENT_WHITELIST"
```

### Step 3: Update the Kibana Ingress (Source of Truth)

Add your IP to the Kibana ingress whitelist. Use CIDR notation (add /32 for single IP):

```bash
NEW_IP="YOUR_IP_HERE"
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="${CURRENT_WHITELIST},${NEW_IP}/32" --overwrite
```

**Example:** To add IP `192.168.1.100`:

```bash
NEW_IP="192.168.1.100"
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="${CURRENT_WHITELIST},${NEW_IP}/32" --overwrite
```

### Step 4: Apply Changes to All Ingresses

Run the consolidated script to propagate the whitelist from Kibana ingress to all other ingresses:

```bash
./apply-ingress-whitelist-consolidated.sh
```

This script will:
1. Retrieve the current IP whitelist from the Kibana ingress
2. Apply it to all 5 protected ingress endpoints
3. Display confirmation for each ingress updated

## How to Remove an IP Address

### Step 1: Get Current Whitelist

```bash
CURRENT_WHITELIST=$(kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range}')
echo "Current whitelist: $CURRENT_WHITELIST"
```

### Step 2: Update the Kibana Ingress

Manually construct the new whitelist without the IP you want to remove:

```bash
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="IP1/32,IP2/32,IP3/32,10.4.0.0/16" --overwrite
```

### Step 3: Apply Changes to All Ingresses

Run the script to propagate the updated whitelist:

```bash
./apply-ingress-whitelist-consolidated.sh
```

## CIDR Notation Guide

The `whitelist-source-range` annotation uses CIDR notation:

- Single IP: `192.168.1.100/32`
- IP range: `192.168.1.0/24` (allows 192.168.1.0 - 192.168.1.255)
- Subnet: `10.4.0.0/16` (allows 10.4.0.0 - 10.4.255.255)

Multiple entries are comma-separated: `IP1/32,IP2/32,10.4.0.0/16`

## Troubleshooting

### I can't access the endpoints

1. **Check your current IP:**
   ```bash
   curl -s -4 ifconfig.me
   ```

2. **Verify it's in the whitelist:**
   ```bash
   kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range}'
   ```

3. **If your IP is missing, add it using the steps above**

### Getting "403 Forbidden"

This means your IP is being blocked. Follow the steps above to add your IP to the whitelist.

### Changes not taking effect

Wait 30-60 seconds for the nginx ingress controller to reload the configuration, then try accessing again.

### Error: "snippet annotation cannot be used"

This is expected. This cluster has snippet directives disabled for security. Always use the `whitelist-source-range` annotation instead of `server-snippet`.

## Differences from DP4 Cluster

The DP4 cluster uses `server-snippet` annotation with nginx directives, while this cluster uses `whitelist-source-range` annotation. This is because:

- DP4: Snippet directives are enabled
- DP1: Snippet directives are disabled (more secure configuration)

Both approaches provide IP whitelisting, but use different nginx ingress controller configurations.

## Security Notes

- IP whitelisting provides basic access control but is not a substitute for proper authentication
- Dynamic IPs (home/mobile connections) will require whitelist updates when they change
- For internal subnet access (10.4.0.0/16), no additional configuration is needed
- The whitelist returns HTTP 403 (Forbidden) for non-whitelisted IPs

## Additional Resources

For more information about nginx ingress annotations:
- [Nginx Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Whitelist Source Range Annotation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#whitelist-source-range)
