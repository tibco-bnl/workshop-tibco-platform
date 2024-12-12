#!/bin/bash

# To run this script, you need to have the following tools installed:
# - Docker Desktop with kubernetes enabled
# - kubectl
# - git

# To run this script on Mac or Linux follow: 
# chmod +x run_platform_provisioner.sh
# sh run_platform_provisioner.sh

# Clone the platform-provisioner repository

PP_GIT_DIR=~/git/tmp
PP_DIR=$PP_GIT_DIR/platform-provisioner
#DOCKER_USERNAME=
#DOCKER_PASSWORD=

echo "Cloning the platform-provisioner repository...Note: This is a forked repository maintained by kulbhushan-tibco with some workarounds."
mkdir -p $PP_GIT_DIR
cd $PP_GIT_DIR

if [ ! -d "$PP_DIR" ]; then
    git clone https://github.com/kulbhushan-tibco/platform-provisioner.git
else
    cd $PP_DIR
    git pull
fi
read -p 'Press [Enter] key to continue...'
# Navigate to the platform-provisioner directory
cd $PP_DIR
echo "----------------------------------------------------------\n"
pwd
echo "----------------------------------------------------------\n"
# Build the Docker image
echo "Building the Docker image for platform-provisioner..."
read -p 'Press [Enter] key to continue...'
cd $PP_DIR/docker
./build.sh

# (Optional)Login to Docker
#docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD" docker.io

# Optionally: Tag and push the Docker image
docker image tag platform-provisioner:latest $USER/platform-provisioner:v1
docker image tag platform-provisioner:latest $USER/platform-provisioner:latest
#docker push $USER/platform-provisioner:v1

# Verify the Docker image
echo "Platform provisioner Docker image with tags"
docker images | grep platform-provisioner

# Set environment variable
export PIPELINE_SKIP_TEKTON_DASHBOARD=false
export PIPELINE_DOCKER_IMAGE=$USER/platform-provisioner

# Use the Docker desktop context
kubectl config use-context docker-desktop

# Install the platform provisioner
export PIPELINE_NAME="generic-runner"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tests/test-local.yaml"

cd $PP_DIR
./dev/platform-provisioner-install.sh

# Wait for Tekton Pipelines to be ready
echo "Waiting for Tekton Pipelines to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-controller -n tekton-pipelines
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-webhook -n tekton-pipelines
read -p 'Press [Enter] key to continue...'

echo "----------------------------------------------------------\n"
#Get the Platform Provisioner UI and access via Browser
echo "Get the Platform Provisioner UI and access via Browser:"
export POD_NAME=$(kubectl get pods --namespace tekton-tasks -l "app.kubernetes.io/name=platform-provisioner-ui,app.kubernetes.io/instance=platform-provisioner-ui" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace tekton-tasks $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
nohup kubectl --namespace tekton-tasks port-forward $POD_NAME 8080:$CONTAINER_PORT > port_forward_output_platform_provisioner.log 2>&1 &
echo "Visit http://localhost:8080 to use your application"
read -p 'Press [Enter] key to continue...'
echo "----------------------------------------------------------\n"
# Port forward Tekton Dashboard
echo "Port forwarding Tekton Dashboard..."
nohup kubectl -n tekton-pipelines port-forward service/tekton-dashboard 9097:9097 > port_forward_output_tekton_dashboard.log 2>&1 &
echo "Open Tekton Dashboard at http://localhost:9097/#/about"
read -p 'Press [Enter] key to continue...'
echo "----------------------------------------------------------\n"

# Install TP Base
echo "Install tp-base recipe"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tp-base/tp-base-on-prem-https-dockerdesktop.yaml"
echo "Update tp-base-on-prem-https-dockerdesktop.yaml with correct values GUI_TP_TLS_CERT and GUI_TP_TLS_KEY "
read -p 'Press [Enter] key to continue...'
./dev/platform-provisioner-pipelinerun.sh
echo "Waiting for helm-install pipeline run to complete..."
echo "!!! Login to tekton dashboard or Platform provisioner UI/Status (press filter button) and let the helm-install pipeline run complete and then continue here"


echo "----------------------------------------------------------\n"
#Install TIBCO Platform Control Plane
echo "Install TIBCO Platform Control Plane"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/controlplane/tp-cp-docker-desktop.yaml"
echo "Update tp-cp-docker-desktop.yaml with correct values GUI_CP_CONTAINER_REGISTRY_PASSWORD"
read -p 'Press [Enter] key to continue...'
./dev/platform-provisioner-pipelinerun.sh



echo "----------------------------------------------------------\n"
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

read -p 'Press [Enter] key to continue...'