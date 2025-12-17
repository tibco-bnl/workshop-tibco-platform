#!/bin/bash

# Script to apply IP whitelist protection to all UI-related ingresses using kubectl annotate
# This script retrieves the existing IP whitelist from the Kibana ingress and applies it to all other UI ingresses

set -e

# Retrieve the existing IP whitelist configuration from Kibana ingress
echo "Retrieving IP whitelist configuration from Kibana ingress..."
IP_WHITELIST=$(kubectl get ingress dp-config-es-kibana -n elastic-system -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/server-snippet}' 2>/dev/null)

# Check if we successfully retrieved the configuration
if [ -z "$IP_WHITELIST" ]; then
    echo "Error: Could not retrieve IP whitelist from Kibana ingress."
    echo "Please ensure the Kibana ingress (dp-config-es-kibana) exists in the elastic-system namespace with IP whitelist configured."
    exit 1
fi

echo "Successfully retrieved IP whitelist configuration."
echo ""
echo "Applying IP whitelist protection to ingresses..."
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
