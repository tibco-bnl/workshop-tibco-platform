#!/bin/bash

# Script to apply IP whitelist protection to all UI-related ingresses using kubectl annotate
# This script retrieves the existing IP whitelist from the Kibana ingress and applies it to all other UI ingresses
# Uses whitelist-source-range annotation (for clusters where snippet directives are disabled)

set -e

# Retrieve the existing IP whitelist configuration from Kibana ingress
echo "Retrieving IP whitelist configuration from Kibana ingress..."
IP_WHITELIST=$(kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/whitelist-source-range}' 2>/dev/null)

# Check if we successfully retrieved the configuration
if [ -z "$IP_WHITELIST" ]; then
    echo "Error: Could not retrieve IP whitelist from Kibana ingress."
    echo "Please ensure the Kibana ingress (dp-config-es-kibana) exists in the elastic-system namespace with IP whitelist configured."
    exit 1
fi

echo "Successfully retrieved IP whitelist configuration: $IP_WHITELIST"
echo ""
echo "Applying IP whitelist protection to ingresses..."
echo "================================================"

echo "1. Applying APM ingress whitelist..."
kubectl annotate ingress dp-config-es-apm -n elastic-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="$IP_WHITELIST" --overwrite

echo "2. Applying Elasticsearch ingress whitelist..."
kubectl annotate ingress dp-config-es-elastic -n elastic-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="$IP_WHITELIST" --overwrite

echo "3. Applying Kibana ingress whitelist (already configured as source)..."
echo "   Skipping - already configured"

echo "4. Applying Grafana ingress whitelist..."
kubectl annotate ingress kube-prometheus-stack-grafana -n prometheus-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="$IP_WHITELIST" --overwrite

echo "5. Applying Prometheus ingress whitelist..."
kubectl annotate ingress kube-prometheus-stack-prometheus -n prometheus-system \
  nginx.ingress.kubernetes.io/whitelist-source-range="$IP_WHITELIST" --overwrite

echo ""
echo "================================================"
echo "All ingress whitelists applied successfully!"
echo ""
echo "Protected endpoints:"
echo "  ✓ apm.dp1.kul.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ elastic.dp1.kul.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ kibana.dp1.kul.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ grafana.dp1.kul.atsnl-emea.azure.dataplanes.pro"
echo "  ✓ prometheus-internal.dp1.kul.atsnl-emea.azure.dataplanes.pro"
echo ""
echo "Note: To add a new IP, update the Kibana ingress whitelist-source-range annotation"
echo "================================================"
