#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if Docker is running
check_docker_running() {
    if ! sudo systemctl is-active --quiet docker; then
        echo "Docker is not running. Starting Docker..."
        sudo systemctl start docker
    else
        echo "Docker is already running."
    fi
}

# Install prerequisites on Ubuntu
install_prerequisites_ubuntu() {
    sudo apt-get update
    sudo apt-get install -y curl wget apt-transport-https
}

# Install prerequisites on macOS
install_prerequisites_macos() {
    brew update
    brew install curl wget
}

# Install k3d
install_k3d() {
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
}

# Remove Traefik ingress controller
remove_traefik() {
    kubectl delete -n kube-system deployment traefik
}

# Install NGINX ingress controller
install_nginx_ingress() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
}

# Prompt user for Kubernetes context
prompt_kube_context() {
    echo "Please enter the Kubernetes context to use:"
    read -r kube_context
    kubectl config use-context "$kube_context"
}

# Main script
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command_exists lsb_release && lsb_release -si | grep -q "Ubuntu"; then
        echo "Detected Ubuntu on WSL"
        install_prerequisites_ubuntu
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS"
    if ! command_exists brew; then
        echo "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    install_prerequisites_macos
else
    echo "Unsupported OS"
    exit 1
fi

# Check if Docker is running
check_docker_running

if ! command_exists k3d; then
    echo "k3d not found, installing..."
    install_k3d
else
    echo "k3d is already installed"
fi

echo "k3d installation script completed"
# Add k3d config to kubeconfig
if command_exists k3d; then
    echo "Adding k3d config to kubeconfig..."
    k3d kubeconfig merge mycluster --kubeconfig-switch-context
fi

# Prompt user for Kubernetes context
if command_exists kubectl; then
    prompt_kube_context
fi

# Remove Traefik and install NGINX ingress controller
if command_exists kubectl; then
    echo "Removing Traefik ingress controller..."
    remove_traefik
    echo "Installing NGINX ingress controller..."
    install_nginx_ingress
fi

# Echo basic commands
echo "Basic k3d commands:"
echo "Create a new cluster: k3d cluster create mycluster"
echo "Delete a cluster: k3d cluster delete mycluster"
echo "List clusters: k3d cluster list"
echo "Get cluster info: kubectl cluster-info"
