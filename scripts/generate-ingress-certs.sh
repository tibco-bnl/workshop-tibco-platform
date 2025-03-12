#!/bin/bash

# This script generates a self-signed certificate authority (CA) and a server certificate for use with NGINX Ingress Controller.
# The script also creates a Kubernetes secret that will be used by NGINX Ingress Controller to serve HTTPS traffic.
# The script also adds the CA certificate to the OS trust store.
# The script also builds a custom truststore for Java applications.

# Prerequisites:
# 1. OpenSSL
# 2. kubectl
# 3. The script assumes that the NGINX Ingress Controller is installed in the "ingress-nginx" namespace.

#Add a function to install prequisites, openssl and kubectl
install_prerequisites() {
    # Install OpenSSL
    if ! command -v openssl &> /dev/null; then
        echo "OpenSSL is not installed. Installing OpenSSL..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac OS
            brew install openssl
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Ubuntu or WSL
            sudo apt-get install openssl
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
#CERT_DIR="${BASE_DIR}/certs"
CONFIG_DIR="${BASE_DIR}/certconf"
SECRET_DIR="${BASE_DIR}/secrets"
INTERMEDIATE_DIR="${BASE_DIR}/intermediate"
FINAL_DIR="${BASE_DIR}/final"
DNS_DOMAIN="localhost.dataplanes.pro"
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
#mkdir -p ${CERT_DIR}
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
    echo "Refer: https://docs.tibco.com/pub/platform-cp/latest/doc/html/Default.htm#UserGuide/using-custom-certificate.htm"
    echo "Refer: https://github.com/tibcofield/tp-poc/tree/main"
}

update_secrets_env() {
    # Extract TLS cert and key from the local files
    TLS_CERT=$(cat ${CHAIN_PEM})
    TLS_KEY=$(cat ${SERVER_KEY})

    # Create or update secrets.env file
    if [ ! -f secrets.env ]; then
        cp secrets.envEmpty secrets.env
    fi

    # Backup secrets.env before updating
    cp secrets.env secrets.env.old
    # Replace placeholders in secrets.env
    sed -i.bak "s|TLS_CERT=.*|TLS_CERT=${TLS_CERT}|g" secrets.env
    sed -i.bak "s|TLS_KEY=.*|TLS_KEY=${TLS_KEY}|g" secrets.env

    # Clean up backup file created by sed
    rm secrets.env.bak

    echo "secrets.env file has been updated with the TLS certificate and key."
}

create_k8s_secret
#update_secrets_env

add_ca_to_os_trust_store() {
    echo "Adding CA certificate to your OS trust store..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Adding CA certificate to Mac OS trust store..."
        sudo security add-trusted-cert -d -r trustRoot -p ssl -k /Library/Keychains/System.keychain ${CA_PEM}
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Adding CA certificate to Linux trust store..."
        sudo cp ${CA_PEM} /usr/local/share/ca-certificates/ca-${DNS_DOMAIN}.crt
        sudo update-ca-certificates
    fi
}

build_custom_truststore() {
    echo "Building a custom truststore..."
    # Install Java if not present 
    if ! command -v java &> /dev/null; then
        echo "Java is not installed. Installing Java..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Mac OS
            brew install openjdk
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Ubuntu or WSL
            sudo apt-get install openjdk
        fi
    fi

    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    cp ${JAVA_HOME}/lib/security/cacerts ${JAVA_HOME}/lib/security/cacertsbackup
    keytool -import -trustcacerts -alias ${DNS_DOMAIN}-test -file ${CA_CRT} -keystore ${JAVA_HOME}/lib/security/cacerts -storepass changeit -noprompt
    echo "Custom truststore built successfully."
}

#add_ca_to_os_trust_store
#build_custom_truststore


echo "Certificates generated successfully."

echo "openssl command to view .csr file"
echo "openssl req -in ${SERVER_CSR} -noout -text"