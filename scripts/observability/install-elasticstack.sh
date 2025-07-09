#!/bin/bash

# Script to install Elastic Cloud on Kubernetes (ECK) operator and Elastic Stack (Elasticsearch, Kibana, and APM Server) using Helm

set -e

# Variables
ECK_VERSION="2.16.0" # Latest version of ECK operator
ELASTIC_VERSION="8.17.3" # Version for Elasticsearch and Kibana
NAMESPACE="elastic-system"
BASE_DOMAIN="localhost.dataplanes.pro"
STORAGE_CLASS="standard" # Replace with your desired Azure AKS storage class
STORAGE_SIZE="15Gi" # 30GB storage size for Elasticsearch
KIBANA_STORAGE_SIZE="5Gi" # 10GB storage size for Kibana
APM_STORAGE_SIZE="5Gi" # 10GB storage size for APM Server

# Function to check if kubectl and helm are installed
check_tools() {
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Please install it and try again."
        exit 1
    fi
    if ! command -v helm &> /dev/null; then
        echo "helm is not installed. Please install it and try again."
        exit 1
    fi
}

# Install ECK operator using Helm
install_eck_operator() {
    echo "Installing ECK operator version $ECK_VERSION..."
    kubectl create namespace $NAMESPACE || true
    helm repo add elastic https://helm.elastic.co
    helm repo update
    helm install eck-operator elastic/eck-operator --namespace $NAMESPACE --version $ECK_VERSION
    echo "ECK operator installed successfully."
}

# Deploy Elasticsearch using Helm
deploy_elasticsearch() {
    echo "Deploying Elasticsearch version $ELASTIC_VERSION..."
    helm install elasticsearch elastic/elasticsearch --namespace $NAMESPACE --version $ELASTIC_VERSION \
        --set replicas=1 \
        --set esConfig.node.store.allow_mmap=false \
        --set ingress.enabled=true \
        --set ingress.ingressClassName=nginx \
        --set ingress.hosts[0]="elasticsearch.$BASE_DOMAIN" \
        --set persistence.storageClass=$STORAGE_CLASS \
        --set persistence.size=$STORAGE_SIZE
    echo "Elasticsearch deployed successfully."
}

# Deploy Kibana using Helm
deploy_kibana() {
    echo "Deploying Kibana version $ELASTIC_VERSION..."
    helm install kibana elastic/kibana --namespace $NAMESPACE --version $ELASTIC_VERSION \
        --set elasticsearchURL=http://elasticsearch.$BASE_DOMAIN \
        --set kibanaURL=http://kibana.$BASE_DOMAIN \
        --set ingress.enabled=true \
        --set ingress.ingressClassName=nginx \
        --set ingress.hosts[0]="kibana.$BASE_DOMAIN" \
        --set persistence.storageClass=$STORAGE_CLASS \
        --set persistence.size=$KIBANA_STORAGE_SIZE
    echo "Kibana deployed successfully."
}

# Deploy APM Server using Helm
deploy_apm_server() {
    echo "Deploying APM Server version $ELASTIC_VERSION..."
    helm install apm-server elastic/apm-server --namespace $NAMESPACE --version $ELASTIC_VERSION \
        --set elasticsearchURL=http://elasticsearch.$BASE_DOMAIN \
        --set kibanaURL=http://kibana.$BASE_DOMAIN \
        --set ingress.enabled=true \
        --set ingress.ingressClassName=nginx \
        --set ingress.hosts[0]="apm.$BASE_DOMAIN" \
        --set persistence.storageClass=$STORAGE_CLASS \
        --set persistence.size=$APM_STORAGE_SIZE
    echo "APM Server deployed successfully."
}

# Print useful URLs and passwords
print_credentials() {
    echo "=================================================="
    echo "Elastic Stack installation completed successfully."
    echo "Useful URLs:"
    echo "Elasticsearch: http://elasticsearch.$BASE_DOMAIN"
    echo "Kibana: http://kibana.$BASE_DOMAIN"
    echo "APM Server: http://apm.$BASE_DOMAIN"
    echo "=================================================="
    echo "To retrieve passwords, use the following commands:"
    echo "Elasticsearch password:"
    kubectl get secret elasticsearch-es-elastic-user -n $NAMESPACE -o=jsonpath='{.data.elastic}' | base64 --decode
    echo "=================================================="
}

# Main script execution
check_tools
install_eck_operator
deploy_elasticsearch
deploy_kibana
deploy_apm_server
print_credentials
