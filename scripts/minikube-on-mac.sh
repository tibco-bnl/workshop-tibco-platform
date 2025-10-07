#!/bin/bash

# Script to install Minikube on macOS
# This script assumes that Docker Desktop is installed and running.
# Run this script as follows: 
# chmod +x minikube-on-mac.sh
# ./minikube-on-mac.sh

# Function to install prerequisites
install_prerequisites() {
    echo "Installing prerequisites..."
    brew update

    # Install kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Installing kubectl..."
        brew install kubectl
    else
        echo "kubectl is already installed."
    fi

    # Install Minikube
    if ! command -v minikube &> /dev/null; then
        echo "Installing Minikube..."
        brew install minikube
    else
        echo "Minikube is already installed."
    fi

    # Install yq
    if ! command -v yq &> /dev/null; then
        echo "Installing yq..."
        brew install yq
    else
        echo "yq is already installed."
    fi

    # Install helm
    if ! command -v helm &> /dev/null; then
        echo "Installing helm..."
        brew install helm
    else
        echo "helm is already installed."
    fi
}

# Function to start Minikube
start_minikube() {
    echo "Starting Minikube..."
    minikube start --cpus 8 --memory 15360 --disk-size "40g" --driver=docker --addons storage-provisioner --kubernetes-version "1.32.0" --extra-config=kubelet.max-pods=500
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
echo "This script assumes that Docker Desktop is installed and running."
install_prerequisites
start_minikube
display_instructions
