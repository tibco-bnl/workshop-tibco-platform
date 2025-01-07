#!/bin/bash

# To run this script, you need to have the following tools installed:
# - Docker Desktop with Kubernetes enabled or MicroK8s
# - kubectl
# - git

# To run this script on Mac or Linux follow: 
# chmod +x run_platform_provisioner.sh
# sh run_platform_provisioner.sh

# Clone the platform-provisioner repository

PP_GIT_DIR=/home/marco/projects/platform-dev
PP_DIR=$PP_GIT_DIR/platform-provisioner
#DOCKER_USERNAME=
#DOCKER_PASSWORD=

#Fix: WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: ~/.kube/config
chmod 600 ~/.kube/config

echo "Cloning the platform-provisioner repository...Note: This is a forked repository maintained by kulbhushan-tibco with some workarounds."
mkdir -p $PP_GIT_DIR
cd $PP_GIT_DIR

if [ ! -d "$PP_DIR" ]; then
    git clone https://github.com/kulbhushan-tibco/platform-provisioner.git
    ##Following branch has most of the workarounds
    git checkout kul-pp
else
    cd $PP_DIR
    echo "Platform-provisioner directory already exists. Stashing your changes and applying them after pulling from remote..."
    git add .
    git stash
    git fetch --all --prune
    git pull
    git stash apply
fi
read -p 'Press [Enter] key to continue...(If error occurs, fix git steps manually in another window to keep your changes and continue or run again)'
# Navigate to the platform-provisioner directory
cd $PP_DIR
echo -e "---We are working from following git repo ----------------"
pwd
echo -e "----------------------------------------------------------"
# Build the Docker image
# echo "Building the Docker image for platform-provisioner..."
# read -p 'Press [Enter] key to continue...'
# cd $PP_DIR/docker
# ./build.sh

# (Optional)Login to Docker
#Ask for DOCKER_USERNAME
# read -p 'Enter your Docker Username: ' DOCKER_USERNAME
# DOCKER_USERNAME=${DOCKER_USERNAME:-$USER}
# echo "Docker Username: $DOCKER_USERNAME"
# echo "Login to Docker"
# docker login -u $DOCKER_USERNAME 

# Optionally: Tag and push the Docker image for microk8s you must login to docker to pull and push images to your own repo
# docker image tag platform-provisioner:latest $DOCKER_USERNAME/platform-provisioner:latest
# docker image tag platform-provisioner:latest $DOCKER_USERNAME/platform-provisioner:v1
# docker push $DOCKER_USERNAME/platform-provisioner:v1
# docker push $DOCKER_USERNAME/platform-provisioner:latest

# Verify the Docker image
# echo "Platform provisioner Docker image with tags"
# docker images | grep platform-provisioner

# read -p 'Press [Enter] key to continue...'

# Set environment variable
export PIPELINE_SKIP_TEKTON_DASHBOARD=false
# export PIPELINE_DOCKER_IMAGE=$DOCKER_USERNAME/platform-provisioner
export PIPELINE_DOCKER_IMAGE=

# List available Kubernetes contexts and ask the user to choose one
echo "Available Kubernetes contexts:"
kubectl config get-contexts -o name

read -p 'Enter the Kubernetes context you want to use: ' KUBE_CONTEXT

# Switch to the selected Kubernetes context
echo "Switching to $KUBE_CONTEXT Kubernetes context..."
kubectl config use-context $KUBE_CONTEXT

# Detect Kubernetes context and set the context accordingly
KUBE_CONTEXT=$(kubectl config current-context)
if [[ "$KUBE_CONTEXT" == "docker-desktop" ]]; then
    echo "Using Docker Desktop Kubernetes context"
    kubectl config use-context docker-desktop
elif [[ "$KUBE_CONTEXT" == "microk8s" ]]; then
    echo "Using MicroK8s Kubernetes context"
    alias kubectl='microk8s kubectl'
else
    echo "Unsupported Kubernetes context: $KUBE_CONTEXT"
    exit 1
fi

read -p 'Press [Enter] key to continue...'

# Install the platform provisioner
export PIPELINE_NAME="generic-runner"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tests/test-local.yaml"
cd $PP_DIR
./dev/platform-provisioner-install.sh

# Wait for Tekton Pipelines to be ready
echo "Waiting for Tekton Pipelines to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-controller -n tekton-pipelines
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-webhook -n tekton-pipelines

echo "----------------------------------------------------------"
# Get the Platform Provisioner UI and access via Browser
echo "Get the Platform Provisioner UI and access via Browser:"
export POD_NAME=$(kubectl get pods --namespace tekton-tasks -l "app.kubernetes.io/name=platform-provisioner-ui,app.kubernetes.io/instance=platform-provisioner-ui" -o jsonpath="{.items[0].metadata.name}")
echo "Forwarding ports for the Platform Provisioner UI and Tekton Dashboard"
nohup kubectl port-forward $POD_NAME 8080:8080 -n tekton-tasks &
nohup kubectl port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines &
echo "----------------------------------------------------------"

# Wait for user input to continue
echo "Next steps include: "
echo "1. Install TP Base"
echo "2. Install TIBCO Platform Control Plane"
echo " You can stop this script here and create both from Platform provisioner UI as well.. which is more interactive and works well"
echo "----------------------------------------------------------"
read -p 'Press [Enter] key to continue...'

# Install TP Base
echo "Install tp-base recipe"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tp-base/tp-base-on-prem-https-$KUBE_CONTEXT.yaml"
echo "Update tp-base-on-prem-https-$KUBE_CONTEXT.yaml with correct values GUI_TP_TLS_CERT and GUI_TP_TLS_KEY "
read -p 'Press [Enter] key to continue...'
./dev/platform-provisioner-pipelinerun.sh
echo "Waiting for helm-install pipeline run to complete..."
echo "!!! Login to tekton dashboard or Platform provisioner UI >> Status >> press filter button and let the helm-install pipeline run complete and then continue here"


echo "----------------------------------------------------------\n"
#Install TIBCO Platform Control Plane
echo "Install TIBCO Platform Control Plane"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/controlplane/tp-cp-$KUBE_CONTEXT.yaml"
echo "Update tp-cp-$KUBE_CONTEXT.yaml with correct values GUI_CP_CONTAINER_REGISTRY_PASSWORD"
read -p 'Press [Enter] key to continue...'
./dev/platform-provisioner-pipelinerun.sh

echo "----------------------------------------------------------\n"
#Make coredns changes 
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/controlplane/tp-config-coredns-$KUBE_CONTEXT.yaml"
read -p 'Press [Enter] key to continue...'
./dev/platform-provisioner-pipelinerun.sh




echo "----------------------SAVE THIS SOMEWHERE or Bookmark------------------------------------\n"
echo "All steps completed successfully. Follow Platform provisioner UI to do following: "
echo "1. Configure admin user"
echo "2. Register DP manually from CP URL and provision capabilities e.g. Flogo, BWCE, EMS, etc."
echo "----------------------------------------------------------\n"
echo "Access the following URLs:"
echo "Mail URL: https://mail.localhost.dataplanes.pro/"
echo "CP URL: https://admin.cp1-my.localhost.dataplanes.pro/admin/app/home"
echo "Tekton Dashboard at http://localhost:9097/#/about"
echo "Platform Provisioner UI: http://localhost:8080"
echo "----------------------------------------------------------\n"
echo "Deploy TIBCO Data Plane on your $KUBE_CONTEXT cluster using CP"
echo "We can also use the same cluster for TIBCO Data Plane."
echo "----------------------------------------------------------\n"
echo "To stop the port forwarding, run the following commands:"
echo "kill $(lsof -t -i:8080)"
echo "kill $(lsof -t -i:9097)"
echo "----------------------------------------------------------\n"
echo "To uninstall the platform provisioner, run the following command:"
echo "cd $PP_DIR"
echo "./dev/platform-provisioner-uninstall.sh"
echo "----------------------------------------------------------\n"

read -p 'Press [Enter] key to continue...'