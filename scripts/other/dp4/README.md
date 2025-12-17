# IP Whitelist Configuration for Ingress Endpoints

This directory contains scripts to manage IP-based access control for UI-related ingress endpoints in the cluster.

## Protected Endpoints

The following endpoints are protected with IP whitelist:

- `bpm.mle.atsnl-emea.azure.dataplanes.pro`
- `apm.mle.atsnl-emea.azure.dataplanes.pro`
- `elastic.mle.atsnl-emea.azure.dataplanes.pro`
- `kibana.mle.atsnl-emea.azure.dataplanes.pro`
- `developerhub.mle.atsnl-emea.azure.dataplanes.pro`
- `grafana.mle.atsnl-emea.azure.dataplanes.pro`
- `prometheus-internal.mle.atsnl-emea.azure.dataplanes.pro`

## Current Whitelisted IPs

- `63.34.112.27`
- `85.145.141.250`
- `217.120.32.76`
- `86.90.167.198`
- `10.4.0.*` (internal subnet)

## How to Add Your IP Address

### Step 1: Find Your Public IP Address

```bash
curl -s -4 ifconfig.me
```

### Step 2: Edit the Script

Open the script file:

```bash
vi apply-ingress-whitelist-consolidated.sh
```

Find the `IP_WHITELIST` variable (around line 13) and add your IP address to the regex pattern:

```bash
IP_WHITELIST='# If not allowed, return blank page
 if ($remote_addr  !~ "^63\.34\.112\.27$|^85\.145\.141\.250$|^217\.120\.32\.76$|^86\.90\.167\.198$|^YOUR_IP_HERE$|^10\.4\.0\..*") {
    return 444;
  }'
```

**Important:** Make sure to escape dots in the IP address with backslash: `\.`

For example, to add IP `192.168.1.100`:
```bash
IP_WHITELIST='# If not allowed, return blank page
 if ($remote_addr  !~ "^63\.34\.112\.27$|^85\.145\.141\.250$|^217\.120\.32\.76$|^86\.90\.167\.198$|^192\.168\.1\.100$|^10\.4\.0\..*") {
    return 444;
  }'
```

### Step 3: Apply the Changes

Run the script to apply the updated whitelist to all ingresses:

```bash
./apply-ingress-whitelist-consolidated.sh
```

## How to Remove an IP Address

### Step 1: Edit the Script

Open the script file:

```bash
vi apply-ingress-whitelist-consolidated.sh
```

### Step 2: Remove the IP

Find the IP address you want to remove in the `IP_WHITELIST` variable and delete it along with the pipe separator `|`.

For example, to remove `86.90.167.198`:

**Before:**
```bash
if ($remote_addr  !~ "^63\.34\.112\.27$|^85\.145\.141\.250$|^217\.120\.32\.76$|^86\.90\.167\.198$|^10\.4\.0\..*") {
```

**After:**
```bash
if ($remote_addr  !~ "^63\.34\.112\.27$|^85\.145\.141\.250$|^217\.120\.32\.76$|^10\.4\.0\..*") {
```

### Step 3: Apply the Changes

Run the script:

```bash
./apply-ingress-whitelist-consolidated.sh
```

## Quick Add Single IP (Alternative Method)

If you need to quickly add your current IP without editing the script:

```bash
# Get your IP
MY_IP=$(curl -s -4 ifconfig.me)

# Add to all ingresses
kubectl annotate ingress bpm-dev-ingress -n bpm \
  nginx.ingress.kubernetes.io/server-snippet="# If not allowed, return blank page
 if (\$remote_addr  !~ \"^63\\.34\\.112\\.27\$|^85\\.145\\.141\\.250\$|^217\\.120\\.32\\.76\$|^86\\.90\\.167\\.198\$|^${MY_IP}\$|^10\\.4\\.0\\..*\") {
    return 444;
  }" --overwrite
```

**Note:** You'll need to repeat this for all 7 ingresses or update the script for consistency.

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
