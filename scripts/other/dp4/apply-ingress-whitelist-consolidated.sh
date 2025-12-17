#!/bin/bash

# Script to apply IP whitelist protection to all UI-related ingresses using kubectl annotate
# Whitelisted IPs:
# - 63.34.112.27
# - 85.145.141.250
# - 217.120.32.76
# - 86.90.167.198 (current IP)
# - 10.4.0.* (internal subnet)

set -e

# Define the IP whitelist configuration
IP_WHITELIST='# If not allowed, return blank page
 if ($remote_addr  !~ "^63\.34\.112\.27$|^85\.145\.141\.250$|^217\.120\.32\.76$|^86\.90\.167\.198$|^10\.4\.0\..*") {
    return 444;
  }'

echo "Applying IP whitelist protection to ingresses..."
echo "================================================"
echo ""
echo "Whitelisted IPs:"
echo "  - 63.34.112.27"
echo "  - 85.145.141.250"
echo "  - 217.120.32.76"
echo "  - 86.90.167.198 (current IP)"
echo "  - 10.4.0.* (internal subnet)"
echo ""
echo "================================================"

echo "1. Applying BPM ingress whitelist..."
kubectl annotate ingress bpm-dev-ingress -n bpm \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "2. Applying APM ingress whitelist..."
kubectl annotate ingress dp-config-es-apm -n elastic-system \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "3. Applying Elasticsearch ingress whitelist..."
kubectl annotate ingress dp-config-es-elastic -n elastic-system \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "4. Applying Kibana ingress whitelist..."
kubectl annotate ingress dp-config-es-kibana -n elastic-system \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "5. Applying Developer Hub ingress whitelist..."
kubectl annotate ingress tibco-developer-hub-cq1qkocrfcpcei39blr0 -n nlpresales-ns \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "6. Applying Grafana ingress whitelist..."
kubectl annotate ingress grafana-ingress -n prometheus-system \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo "7. Applying Prometheus ingress whitelist..."
kubectl annotate ingress kube-prometheus-stack-prometheus -n prometheus-system \
  nginx.ingress.kubernetes.io/server-snippet="$IP_WHITELIST" --overwrite

echo ""
echo "================================================"
echo "All ingress whitelists applied successfully!"
echo ""
echo "Protected endpoints:"
echo "  ✓ bpm.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ apm.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ elastic.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ kibana.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ developerhub.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ grafana.mle.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ prometheus-internal.mle.atsnl-emea.azure.dataplanes.pro"
echo ""
echo "Note: To add a new IP, edit the IP_WHITELIST variable in this script"
echo "================================================"
