#!/bin/bash

# To run this script, you need to have the following tools installed:
# - Docker Desktop with Kubernetes enabled or MicroK8s/Minikube
# - kubectl
# - git
# - yq

# copy scripts/secrets.envEmpty to scripts/secrets.env
# replace values in file scripts/secrets.env
# NEVER PUSH this file to git!!!!


# To run this script on Mac or Linux follow: 
# chmod +x run_platform_provisioner.sh
# ./run_platform_provisioner.sh


# function to color text for user input
RED="\033[32m" # Red 31 is green 32 now as well for better visibility
GREEN="\033[32m"
ENDCOLOR="\033[0m"
function enter_to_continue() { 
        echo -e "${RED}Press [Enter] key to continue... ${ENDCOLOR} "
        read 
        }

# current directory from which
WORKSHOP_SCRIPT_DIR=$(pwd)
WORKSHOP_BASE_DIR=$WORKSHOP_SCRIPT_DIR/..

# Clone the platform-provisioner repository
PP_GIT_DIR=~/git/tmp
PP_DIR=$PP_GIT_DIR/platform-provisioner

        # Typeical variables which are supposed to be changed from the default values.
        #
        # Used environment variables to be set in the secrets file:
        #
        # TLS_CERT=--
        # TLS_KEY=--
        # STORAGE_CLASS_MINIKUBE=standard
        # STORAGE_CLASS_DOCKERDESKTOP=hostpath
        # STORAGE_CLASS_MICROK8S=microk8s-hostpath
        # CONTAINER_REGISTRY=csgprdusw2reposaas.jfrog.io
        # CONTAINER_REGISTRY_REPOSITORY=tibco-platform-docker-dev
        # CONTAINER_REGISTRY_USERNAME=
        # CONTAINER_REGISTRY_PASSWORD


## read secrets from .env file and load into environment as env variables
SECRETS_FILE=$WORKSHOP_BASE_DIR/scripts/secrets.env
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Secret file $SECRETS_FILE not found. Please correct and restart." 
    exit 1
fi
export $(grep -v '^#' $SECRETS_FILE | xargs)

#Fix: WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: ~/.kube/config
chmod 600 ~/.kube/config

echo "Cloning the platform-provisioner repository...Note: This is a forked repository maintained by kulbhushan-tibco with some workarounds."
echo ""

mkdir -p $PP_GIT_DIR
cd $PP_GIT_DIR

if [ ! -d "$PP_DIR" ]; then
    git clone https://github.com/TIBCOSoftware/platform-provisioner.git
    #git clone https://github.com/kulbhushan-tibco/platform-provisioner.git
    echo ""

    ##Following branch has most of the workarounds
    cd platform-provisioner
    #git checkout kul-pp
    echo ""

else
    cd $PP_DIR
    echo "Platform-provisioner directory already exists. Stashing your changes and applying them after pulling from remote..."
    echo ""
    git add .
    git stash
    echo ""
    git fetch --all --prune
    echo ""
    git pull
    echo ""
    git stash apply
    echo ""

fi
echo "If error occured, fix git steps manually in another window to keep your changes and continue or run again" 
echo ""
enter_to_continue

# Navigate to the platform-provisioner directory
cd $PP_DIR
echo ""
echo -e "---We are working from following git repo ----------------"
pwd
echo -e "----------------------------------------------------------"
echo ""


# Set environment variable
export PIPELINE_SKIP_TEKTON_DASHBOARD=false
# PIPELINE_DOCKER_IMAGE is emtpy to use default platform image from tibcosoftware repository
export PIPELINE_DOCKER_IMAGE=


# List available Kubernetes contexts and ask the user to choose one
echo "Available Kubernetes contexts:"
kubectl config get-contexts -o name
echo ""

echo -e "${RED}Enter the Kubernetes context you want to use: ${ENDCOLOR} "
read -p "" KUBE_CONTEXT
echo ""
# Switch to the selected Kubernetes context
echo "Switching to $KUBE_CONTEXT Kubernetes context..."
kubectl config use-context $KUBE_CONTEXT
echo ""

# Detect Kubernetes context and set the context accordingly
KUBE_CONTEXT=$(kubectl config current-context)
if [[ "$KUBE_CONTEXT" == "docker-desktop" ]]; then
    echo ""
    echo "Using Docker Desktop Kubernetes context"
    kubectl config use-context docker-desktop
    export STORAGE_CLASS_CLUSTER=$STORAGE_CLASS_DOCKERDESKTOP
    echo ""
elif [[ "$KUBE_CONTEXT" == "microk8s" ]]; then
    echo "Using MicroK8s Kubernetes context"
    alias kubectl='microk8s kubectl'
    export STORAGE_CLASS_CLUSTER=$STORAGE_CLASS_MICROK8S
    echo ""
elif [[ "$KUBE_CONTEXT" == "minikube" ]]; then
    echo "Using MiniKube Kubernetes context"
    alias kubectl='minikube kubectl'
    export STORAGE_CLASS_CLUSTER=$STORAGE_CLASS_MINIKUBE
    echo ""
else
    echo ""
    echo "Unsupported Kubernetes context: $KUBE_CONTEXT"
    exit 1
fi

##
# Replace key values in the recipes used for this installation
#
# TIBCO PLATFORM Base recipe
echo "Replace variables in recipes"

RECIPE_TP_BASE=$PP_DIR/docs/recipes/tp-base/tp-base-on-prem-https.yaml
#replace values in the recipes
#echo "replacement values: $TLS_CERT, $TLS_KEY, $STORAGE_CLASS_CLUSTER"
yq e -i '.meta.guiEnv.GUI_TP_TLS_CERT=env(TLS_CERT)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_TLS_KEY=env(TLS_KEY)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_STORAGE_CLASS=env(STORAGE_CLASS_CLUSTER)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_CONTAINER_REGISTRY_URL=env(CONTAINER_REGISTRY)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_CONTAINER_REGISTRY_REPOSITORY=env(CONTAINER_REGISTRY_REPOSITORY)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_CONTAINER_REGISTRY_USERNAME=env(CONTAINER_REGISTRY_USERNAME)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_CONTAINER_REGISTRY_PASSWORD=env(CONTAINER_REGISTRY_PASSWORD)' $RECIPE_TP_BASE
yq e -i '.meta.guiEnv.GUI_TP_DNS_DOMAIN=env(DNS_DOMAIN)' $RECIPE_TP_BASE

#
# TIBCO PLATFORM Control Plane
RECIPE_TP_CP=$PP_DIR/docs/recipes/controlplane/tp-cp.yaml
#replace values in the recipes

    # remove the default -my from CP instance id
yq e -i '.meta.globalEnvVariable.CP_SERVICE_DNS_DOMAIN |= sub("-my\\."; ".")' $RECIPE_TP_CP
yq e -i '.meta.guiEnv.GUI_CP_CONTAINER_REGISTRY=env(CONTAINER_REGISTRY)' $RECIPE_TP_CP
yq e -i '.meta.guiEnv.GUI_CP_CONTAINER_REGISTRY_REPOSITORY=env(CONTAINER_REGISTRY_REPOSITORY)' $RECIPE_TP_CP
yq e -i '.meta.guiEnv.GUI_CP_CONTAINER_REGISTRY_USERNAME=env(CONTAINER_REGISTRY_USERNAME)' $RECIPE_TP_CP
yq e -i '.meta.guiEnv.GUI_CP_CONTAINER_REGISTRY_PASSWORD=env(CONTAINER_REGISTRY_PASSWORD)' $RECIPE_TP_CP
echo "Recipes updated....."
echo ""
echo "Ready to deploy provisioner and tekton tooling" 
echo ""
enter_to_continue
echo ""
# Install the platform provisioner
export PIPELINE_NAME="generic-runner"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tests/test-local.yaml"
cd $PP_DIR
./dev/platform-provisioner-install.sh
echo ""

# Wait for Tekton Pipelines to be ready
echo ""
echo "Waiting for Tekton Pipelines to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-controller -n tekton-pipelines
kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-webhook -n tekton-pipelines
echo ""
echo "----------------------------------------------------------"
# Get the Platform Provisioner UI and access via Browser
echo "Get the Platform Provisioner UI and access via Browser:"
$WORKSHOP_SCRIPT_DIR/port_forwarder.sh provisioner
$WORKSHOP_SCRIPT_DIR/port_forwarder.sh tekton
echo "----------------------------------------------------------"

# Wait for user input to continue
echo "Next steps include: "
echo "- Install TP Base"
echo "- Install TIBCO Platform Control Plane"
echo " You can stop this script here and create both from Platform provisioner UI as well.. which is more interactive and works well"
echo "----------------------------------------------------------"
echo ""
enter_to_continue

# Install TP Base
echo ""
echo "Install tp-base recipe"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/tp-base/tp-base-on-prem-https.yaml"

echo ""
./dev/platform-provisioner-pipelinerun.sh

echo ""
echo "Waiting for helm-install pipeline run to complete..."
echo ""
echo "!!! Login to tekton dashboard or Platform provisioner UI >> Status >> press filter button and let the helm-install pipeline run complete and then continue here"
echo ""
echo "----------------------------------------------------------\n"
enter_to_continue

#Install TIBCO Platform Control Plane
echo ""
echo "Install TIBCO Platform Control Plane"
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$PP_DIR/docs/recipes/controlplane/tp-cp.yaml"
# echo ""
# echo -e "Update recipe ${GREEN}${PIPELINE_INPUT_RECIPE}${ENDCOLOR} with correct values GUI_CP_CONTAINER_REGISTRY_PASSWORD"
echo ""
enter_to_continue
./dev/platform-provisioner-pipelinerun.sh
echo ""
echo "----------------------------------------------------------\n"
echo ""
echo "Waiting for helm-install pipeline run to complete..."
echo ""
echo "!!! Login to tekton dashboard or Platform provisioner UI >> Status >> press filter button and let the helm-install pipeline run complete and then continue here"
echo ""
echo "----------------------------------------------------------\n"
enter_to_continue

#Make coredns changes 

export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$WORKSHOP_BASE_DIR/docs/recipes/controlplane/tp-config-coredns-$KUBE_CONTEXT.yaml"
echo ""
echo ""
echo "Update coredns configuration"
echo ""
./dev/platform-provisioner-pipelinerun.sh
echo "Done"
echo "Next step: Install Observability"

enter_to_continue

# Install Observability 
export PIPELINE_NAME="helm-install"
export PIPELINE_INPUT_RECIPE="$WORKSHOP_BASE_DIR/docs/recipes/observability/tp-observability-$KUBE_CONTEXT.yaml"
echo ""
echo ""
echo "Install Observability ... "
echo ""
./dev/platform-provisioner-pipelinerun.sh
echo "Done"
echo "You can access kibana, grafana, prometheus, apm, etc via default ingress and by default the port_forwarder.sh script will forward the ports to localhost"
echo "----------------------------------------------------------\n"

enter_to_continue

$WORKSHOP_SCRIPT_DIR/port_forwarder.sh ingress $KUBE_CONTEXT

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
echo "Kibana: http://kibana.localhost.dataplanes.pro/"
echo "Username: elastic Password: "
echo "Get elastic password:  kubectl get secret dp-config-es-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 --decode"
echo "Grafana: http://grafana.localhost.dataplanes.pro/"
echo "Default Grafana username: admin, password: prom-operator"
echo "Prometheus: http://prometheus.localhost.dataplanes.pro/"
echo "Default prometheus username: admin, password: prom-operator"
echo "APM: http://apm.localhost.dataplanes.pro/"
echo "----------------------------------------------------------------\n"
echo "Deployed TIBCO Data Plane on your $KUBE_CONTEXT cluster using CP"
echo "We can also use the same cluster for TIBCO Data Plane."
echo "-----------------------------------------------------------------\n"
echo "To stop the port forwarding, run the following commands:"
echo "kill $(lsof -t -i:8080)"
echo "kill $(lsof -t -i:9097)"
echo "kill $(sudo lsof -t -i:80)"
echo "----------------------------------------------------------\n"
echo "To uninstall the platform provisioner, run the following command:"
echo "cd $PP_DIR"
echo "./dev/platform-provisioner-uninstall.sh"
echo "----------------------------------------------------------\n"

enter_to_continue


