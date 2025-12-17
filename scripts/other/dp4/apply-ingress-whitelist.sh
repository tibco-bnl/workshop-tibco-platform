#!/bin/bash

# Script to apply IP whitelist protection to all UI-related ingresses
# Whitelisted IPs:
# - 63.34.112.27
# - 85.145.141.250
# - 217.120.32.76
# - 86.90.167.198 (current IP)
# - 10.4.0.* (internal subnet)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Applying IP whitelist protection to ingresses..."
echo "================================================"

echo "1. Applying BPM ingress whitelist..."
kubectl patch ingress bpm-dev-ingress -n bpm --type=merge --patch-file="${SCRIPT_DIR}/bpm-ingress-whitelist.yaml"

echo "2. Applying APM ingress whitelist..."
kubectl patch ingress dp-config-es-apm -n elastic-system --type=merge --patch-file="${SCRIPT_DIR}/apm-ingress-whitelist.yaml"

echo "3. Applying Elasticsearch ingress whitelist..."
kubectl patch ingress dp-config-es-elastic -n elastic-system --type=merge --patch-file="${SCRIPT_DIR}/elastic-ingress-whitelist.yaml"

echo "4. Applying Kibana ingress whitelist..."
kubectl patch ingress dp-config-es-kibana -n elastic-system --type=merge --patch-file="${SCRIPT_DIR}/kibana-ingress-whitelist.yaml"

echo "5. Applying Developer Hub ingress whitelist..."
kubectl patch ingress tibco-developer-hub-cq1qkocrfcpcei39blr0 -n nlpresales-ns --type=merge --patch-file="${SCRIPT_DIR}/developerhub-ingress-whitelist.yaml"

echo "6. Applying Grafana ingress whitelist..."
kubectl patch ingress grafana-ingress -n prometheus-system --type=merge --patch-file="${SCRIPT_DIR}/grafana-ingress-whitelist.yaml"

echo "7. Applying Prometheus ingress whitelist..."
kubectl patch ingress kube-prometheus-stack-prometheus -n prometheus-system --type=merge --patch-file="${SCRIPT_DIR}/prometheus-ingress-whitelist.yaml"

echo "================================================"
echo "All ingress whitelists applied successfully!"
echo ""
echo "Protected ingresses:"
echo "  - bpm.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - apm.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - elastic.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - kibana.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - developerhub.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - grafana.mle.atsnl-emea.azure.dataplanes.pro"
echo "  - prometheus-internal.mle.atsnl-emea.azure.dataplanes.pro"
