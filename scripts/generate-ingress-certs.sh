#!/bin/bash

# This script generates a self-signed certificate authority (CA) and a server certificate for use with NGINX Ingress Controller.
# The script also creates a Kubernetes secret that will be used by NGINX Ingress Controller to serve HTTPS traffic.
# The script also adds the CA certificate to the OS trust store.
# The script also builds a custom truststore for Java applications.

# Usage:
# ./generate-ingress-certs.sh <DNS_DOMAIN>
# Example:
# ./generate-ingress-certs.sh localhost.dataplanes.pro

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DNS_DOMAIN>"
    echo "Example: $0 localhost.dataplanes.pro"
    exit 1
fi

DNS_DOMAIN="$1"

# Variables
BASE_DIR="./certs"
CONFIG_DIR="${BASE_DIR}/certconf"
SECRET_DIR="${BASE_DIR}/secrets"
INTERMEDIATE_DIR="${BASE_DIR}/intermediate"
FINAL_DIR="${BASE_DIR}/final"
CA_KEY="${INTERMEDIATE_DIR}/ca-${DNS_DOMAIN}.key"
CA_CRT="${INTERMEDIATE_DIR}/ca-${DNS_DOMAIN}.crt"
CA_PEM="${INTERMEDIATE_DIR}/ca-${DNS_DOMAIN}.pem"
SERVER_KEY="${INTERMEDIATE_DIR}/server-${DNS_DOMAIN}.key"
SERVER_CSR="${INTERMEDIATE_DIR}/server-${DNS_DOMAIN}.csr"
SERVER_PEM="${INTERMEDIATE_DIR}/server-${DNS_DOMAIN}.pem"
SECRET_SECRET="${SECRET_DIR}/default-certificate-secret.yaml"
CHAIN_PEM="${FINAL_DIR}/server-${DNS_DOMAIN}-chain.pem"
NAMESPACE="ingress-nginx"

# Create directories if they don't exist
echo "Creating directories if they don't exist..."
mkdir -p ${CONFIG_DIR}
mkdir -p ${SECRET_DIR}
mkdir -p ${INTERMEDIATE_DIR}
mkdir -p ${FINAL_DIR}

# Clean previously created files
echo "Cleaning previously created files..."
rm -f ${CA_KEY} ${CA_CRT} ${CA_PEM} ${SERVER_KEY} ${SERVER_CSR} ${SERVER_PEM} ${CHAIN_PEM} ${SECRET_SECRET}

# Create CA certificate
echo "Creating CA certificate..."
openssl req -x509 -newkey rsa:4096 -keyout ${CA_KEY} -outform DER -out ${CA_CRT} -sha256 -days 3650 -nodes -subj "/C=GB/ST=LONDON/L=EAST/O=TIBCO PLATFORM TESTING/OU=DEV/CN=TIBCO Platform TEST CA"

# Convert the binary encoded CA CRT file into a PEM file
echo "Converting CA certificate to PEM format..."
openssl x509 -in ${CA_CRT} -inform DER -out ${CA_PEM} -outform PEM

# Create Server Certificate
echo "Creating Server certificate..."
openssl genrsa -out ${SERVER_KEY} 4096
openssl req -new -config ${CONFIG_DIR}/server.cnf -key ${SERVER_KEY} -out ${SERVER_CSR} -outform PEM
openssl x509 -req -in ${SERVER_CSR} -CA ${CA_CRT} -CAkey ${CA_KEY} -CAcreateserial -outform PEM -out ${SERVER_PEM} -days 825 -extfile ${CONFIG_DIR}/server.ext

# Combine the CA Authority and Server PEM files
echo "Combining CA and Server PEM files..."
cat ${SERVER_PEM} ${CA_PEM} >> ${CHAIN_PEM}

create_k8s_secret() {
    echo "Creating Kubernetes secret to be used by NGINX with name 'default-certificate'..."
    kubectl create secret generic default-certificate --from-file=tls.crt=${CHAIN_PEM} --from-file=tls.key=${SERVER_KEY} --type=Opaque --dry-run=client -o yaml > ${SECRET_DIR}/default-certificate-secret.yaml 
    echo "Kubernetes secret created successfully."
    echo "Apply the secret using the following command:"
    echo "kubectl apply -f ${SECRET_DIR}/default-certificate-secret.yaml -n ${NAMESPACE}"
    echo "Restart the ingress pod to apply the new certificate."
    echo "You must specify the secret name when registering a data plane."
    echo "Restart tibtunnel, cp-proxy, and OAuth2 proxy deployments, which can be done by using the following three commands:"
    echo "kubectl rollout restart -n <namespace> deployment/tp-tibtunnel"
    echo "kubectl rollout restart -n <namespace> deployment/tp-cp-proxy"
    echo "kubectl rollout restart -n <namespace> deployment/oauth2-proxy"
    echo "Refer: https://docs.tibco.com/pub/platform-cp/latest/doc/html/Default.htm#UserGuide/using-custom-certificate.htm"
    echo "Refer: https://github.com/tibcofield/tp-poc/tree/main"
}

create_k8s_secret

echo "Certificates generated successfully."

echo "openssl command to view .csr file"
echo "openssl req -in ${SERVER_CSR} -noout -text"
