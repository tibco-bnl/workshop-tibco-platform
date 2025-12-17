# IP Whitelist Configuration for Ingress Endpoints

This directory contains scripts to manage IP-based access control for UI-related ingress endpoints in the cluster.

## Overview

The script retrieves the IP whitelist configuration from the Kibana ingress (which serves as the source of truth) and applies it to all other UI ingress endpoints, ensuring consistent access control across all protected services.

## Protected Endpoints

The following endpoints are protected with IP whitelist:

- `bpm.mle.atsnl-emea.azure.dataplanes.pro`
- `apm.mle.atsnl-emea.azure.dataplanes.pro`
- `elastic.mle.atsnl-emea.azure.dataplanes.pro`
- `kibana.mle.atsnl-emea.azure.dataplanes.pro`
- `developerhub.mle.atsnl-emea.azure.dataplanes.pro`
- `grafana.mle.atsnl-emea.azure.dataplanes.pro`
- `prometheus-internal.mle.atsnl-emea.azure.dataplanes.pro`

## How to View Current Whitelisted IPs

To see the current whitelisted IP addresses:

```bash
kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/server-snippet}'
```

## How to Add Your IP Address

### Step 1: Find Your Public IP Address

```bash
curl -s -4 ifconfig.me
```

### Step 2: Update the Kibana Ingress (Source of Truth)

Add your IP to the Kibana ingress whitelist. Replace `YOUR_NEW_IP` with your actual IP address:

```bash
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/server-snippet='# If not allowed, return blank page
 if ($remote_addr  !~ "^EXISTING_IP_1$|^EXISTING_IP_2$|^YOUR_NEW_IP$|^10\.4\.0\..*") {
    return 444;
  }' --overwrite
```

**Important:** 
- Make sure to escape dots in IP addresses with backslash: `\.`
- Include all existing IPs plus your new one
- Get existing IPs first using the command in the section above

### Step 3: Apply Changes to All Ingresses

Run the consolidated script to propagate the whitelist from Kibana ingress to all other ingresses:

```bash
./apply-ingress-whitelist-consolidated.sh
```

This script will automatically retrieve the IP whitelist from the Kibana ingress and apply it to all protected endpoints.

## How to Remove an IP Address

### Step 1: Update the Kibana Ingress

Remove the IP from the Kibana ingress whitelist. Make sure to include all IPs you want to keep:

```bash
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/server-snippet='# If not allowed, return blank page
 if ($remote_addr  !~ "^REMAINING_IP_1$|^REMAINING_IP_2$|^10\.4\.0\..*") {
    return 444;
  }' --overwrite
```

### Step 2: Apply Changes to All Ingresses

Run the script to propagate the updated whitelist:

```bash
./apply-ingress-whitelist-consolidated.sh
```

## Apply Whitelist to All Ingresses

To sync the IP whitelist from Kibana ingress (source of truth) to all other UI ingresses:

```bash
cd /path/to/scripts/other/dp4
./apply-ingress-whitelist-consolidated.sh
```

The script will:
1. Retrieve the current IP whitelist from the Kibana ingress
2. Apply it to all 7 protected ingress endpoints
3. Display confirmation for each ingress updated

## Troubleshooting

### I can't access the endpoints

1. **Check your current IP:**
   ```bash
   curl -s -4 ifconfig.me
   ```

2. **Verify it's in the whitelist:**
   ```bash
   kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/server-snippet}'
   ```

3. **If your IP is missing, add it using the steps above**

### Changes not taking effect

Wait 30-60 seconds for the nginx ingress controller to reload the configuration, then try accessing again.

### I'm getting a blank page or connection refused

This means your IP is being blocked. Follow the steps above to add your IP to the whitelist.

## Security Notes

- IP whitelisting provides basic access control but is not a substitute for proper authentication
- Dynamic IPs (home/mobile connections) will require whitelist updates when they change
- For internal subnet access (10.4.0.*), no additional configuration is needed
- The current configuration returns HTTP 444 (connection closed) for non-whitelisted IPs

## Additional Resources

For more information about nginx ingress annotations:
- [Nginx Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Server Snippet Annotation](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#server-snippet)
