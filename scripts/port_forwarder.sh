#!/bin/bash

########################################################################################################
##
## Script to forward ports for TIBCO Platform CP
##
########################################################################################################


 KUBE_CONTEXT=$2

function forward_ingress() {
    echo "Port forwarding 443 and 80 for minikube which only root user can do for minikube"
    echo "If asked please provide password for user $USER to perform sudo action"

    echo "kube context is '$KUBE_CONTEXT'"
    #If KUBE_CONTEXT is minikube, port forward 443 and 80 and it can be done only using root user
    if [[ "$KUBE_CONTEXT" == "minikube" ]]; then
        echo "updating kubeconfig for root user"
        sudo mkdir -p /root/.kube
        sudo cp /home/tibco/.kube/config /root/.kube/config
    fi

    nohu./p sudo kubectl port-forward -n ingress-system --address 0.0.0.0 service/ingress-nginx-controller 80:http 443:https  >/dev/null 2>&1 &
}

function forward_tekton() {
    
    echo "Port forwarding tekton service (9097)"
    nohup kubectl port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines >/dev/null 2>&1 &

    }

function forward_provisioner() {

    echo "Port forwarding provisioner UI (8080)"

    export POD_NAME=$(kubectl get pods --namespace tekton-tasks -l "app.kubernetes.io/name=platform-provisioner-ui,app.kubernetes.io/instance=platform-provisioner-ui" -o jsonpath="{.items[0].metadata.name}")
    export CONTAINER_PORT=$(kubectl get pod --namespace tekton-tasks $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
    nohup kubectl --namespace tekton-tasks port-forward $POD_NAME 8080:$CONTAINER_PORT  >/dev/null 2>&1 &

}


case $1 in

    "tekton")
    forward_tekton
    ;;

    "provisioner")
    forward_provisioner
    ;;

    "ingress")
    forward_ingress
    ;;

    "all")
    echo "Enabling all port-forwards"
    forward_provisioner
    forward_tekton
    forward_ingress
    ;;

    *)
    echo "Incorrect value provided"
    echo "Valid values: tekton, provisioner, ingress, all"
    echo "."

esac

