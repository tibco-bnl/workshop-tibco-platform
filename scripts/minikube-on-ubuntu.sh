#!/bin/bash

# Script to install Minikube on Ubuntu
# Run this scipt as follows: 
# chmod +x minikube-on-ubuntu.sh
# ./minikube-on-ubuntu.sh

# Function to install prerequisites
install_prerequisites() {
    echo "Installing prerequisites..."
    sudo apt-get update -y
    sudo apt-get install -y curl wget apt-transport-https ca-certificates

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker $USER
        newgrp docker
    else
        echo "Docker is already installed."
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        sudo snap install kubectl --classic
    else
        echo "kubectl is already installed."
    fi

    # Install Minikube
    if ! command -v minikube &> /dev/null; then
        echo "Installing Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    else
        echo "Minikube is already installed."
    fi

    # Install yq
    if ! command -v yq &> /dev/null; then
        echo "Installing yq..."
        sudo snap install yq
    else
        echo "yq is already installed."
    fi

    # Install helm
    if ! command -v helm &> /dev/null; then
        echo "Installing helm..."
        sudo snap install helm --classic
    else
        echo "helm is already installed."
    fi
}

# Function to start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube start --cpus 8 --memory 15360 --disk-size "40g" --driver=docker --addons storage-provisioner --kubernetes-version "1.30.0" --extra-config=kubelet.max-pods=500
}

# Function to display common Minikube commands
display_instructions() {
    echo "Minikube has been started successfully."
    echo "Common Minikube commands:"
    echo "  minikube status                - Check the status of Minikube"
    echo "  minikube stop                  - Stop Minikube"
    echo "  minikube delete                - Delete Minikube cluster"
    echo "  minikube dashboard             - Open Minikube dashboard"
    echo "  kubectl get pods               - List all pods in the default namespace"
}

# Main script execution
install_prerequisites
start_minikube
display_instructions
