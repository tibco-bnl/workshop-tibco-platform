#!/bin/bash

# Script to install Minikube on Ubuntu
# Run this scipt as follows: 
# chmod +x minikube-on-ubuntu.sh
# ./minikube-on-ubuntu.sh


# Function to install prerequisites
install_prerequisites() {
    echo "Installing prerequisites..."
    sudo apt-get update -y
    sudo apt-get install -y curl wget apt-transport-https

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
        sudo usermod -aG docker $USER
        newgrp docker
    else
        echo "Docker is already installed."
    fi

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
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
}

# Function to start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube start --cpus 4 --memory 12000 --disk-size "15g" --driver=docker --addons storage-provisioner --kubernetes-version "1.30.0"
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
