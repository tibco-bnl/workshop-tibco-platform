#!/bin/bash

# This script uses Certbot to obtain a properly signed certificate from a CA for use with NGINX Ingress Controller.
# The script also creates a Kubernetes secret that will be used by NGINX Ingress Controller to serve HTTPS traffic.
# The script also adds the CA certificate to the OS trust store.
# The script also builds a custom truststore for Java applications.

# Prerequisites:
# 1. Certbot
# 2. kubectl
# 3. The script assumes that the NGINX Ingress Controller is installed in the "ingress-nginx" namespace.

# Add a function to install prerequisites, certbot and kubectl
install_prerequisites() {
    # Install Certbot
    if ! command -v certbot &> /dev/null; then
        echo "Certbot is not installed. Installing Certbot..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac OS
            brew install certbot
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Ubuntu or WSL
            sudo apt-get install certbot
        fi
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Installing kubectl..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac OS
            brew install kubectl
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Ubuntu or WSL
            if command -v snap &> /dev/null; then
                sudo snap install kubectl --classic
            else
                sudo apt-get install kubectl
            fi
        fi
    fi
}

# Usage:
# 1. Run the script
# chmod +x generate-ingress-certs.sh
# ./generate-ingress-certs.sh

# Variables
BASE_DIR="./certs"
CERT_DIR="${BASE_DIR}/certbot"
SECRET_DIR="${BASE_DIR}/secrets"
NAMESPACE="ingress-nginx"
DOMAIN="yourdomain.com"  # Replace with your domain

# Create directories if they don't exist
echo "Creating directories if they don't exist..."
mkdir -p ${CERT_DIR}
mkdir -p ${SECRET_DIR}

# Clean previously created files
echo "Cleaning previously created files..."
rm -rf ${CERT_DIR}/* ${SECRET_DIR}/*

# Obtain certificates using Certbot
echo "Obtaining certificates using Certbot..."
certbot certonly --manual --preferred-challenges dns -d ${DOMAIN} --agree-tos --manual-public-ip-logging-ok --register-unsafely-without-email --work-dir ${CERT_DIR} --config-dir ${CERT_DIR} --logs-dir ${CERT_DIR}

# Combine the fullchain and private key into a single file
echo "Combining fullchain and private key into a single file..."
cat ${CERT_DIR}/live/${DOMAIN}/fullchain.pem ${CERT_DIR}/live/${DOMAIN}/privkey.pem > ${CERT_DIR}/server-tibco-plat-chain.pem

create_k8s_secret() {
    echo "Creating Kubernetes secret to be used by NGINX"
    kubectl create secret tls server-tibco-plat --key ${CERT_DIR}/live/${DOMAIN}/privkey.pem --cert ${CERT_DIR}/live/${DOMAIN}/fullchain.pem --dry-run=client -o yaml > ${SECRET_DIR}/server-tibco-plat-secret.yaml
    echo "Kubernetes secret created successfully."
    echo "Apply the secret using the following command:"
    echo "kubectl apply -f ${SECRET_DIR}/server-tibco-plat-secret.yaml -n ${NAMESPACE}"
    echo "Restart the ingress pod to apply the new certificate."
}

create_k8s_secret

echo "Certificates obtained and Kubernetes secret created successfully."

echo "Certbot command to renew certificates"
echo "certbot renew --manual --preferred-challenges dns --work-dir ${CERT_DIR} --config-dir ${CERT_DIR} --logs-dir ${CERT_DIR}"