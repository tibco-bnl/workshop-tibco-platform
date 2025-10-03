#!/bin/bash

########################################################################################################
##
## Script to forward ports for TIBCO Platform CP
##
########################################################################################################

KUBE_CONTEXT=$2

function forward_ingress() {
    while true; do
        if [[ "$KUBE_CONTEXT" == "minikube" ]]; then
            USER_TO_COPY=""
            if id "tibco" &>/dev/null && [[ -f /home/tibco/.kube/config ]]; then
                USER_TO_COPY="tibco"
            else
                for u in $(ls /home); do
                    if [[ -f /home/$u/.kube/config ]]; then
                        USER_TO_COPY="$u"
                        break
                    fi
                done
            fi

            if [[ -n "$USER_TO_COPY" ]]; then
                sudo mkdir -p /root/.kube
                sudo cp /home/$USER_TO_COPY/.kube/config /root/.kube/config
            fi
        fi

        if pgrep -f "kubectl port-forward.*ingress-nginx-controller.*80:http 443:https" >/dev/null; then
            sleep 5
        else
            echo "Restarting port-forward for ingress-nginx-controller on ports 80 and 443."
            nohup sudo kubectl port-forward -n ingress-system --address 0.0.0.0 service/ingress-nginx-controller 80:http 443:https >/dev/null 2>&1 &
            sleep 5
        fi
    done
}

function forward_tekton() {
    while true; do
        if pgrep -f "kubectl port-forward.*svc/tekton-dashboard.*9097:9097" >/dev/null; then
            sleep 5
        else
            echo "Restarting port-forward for tekton-dashboard (9097)"
            nohup kubectl port-forward svc/tekton-dashboard 9097:9097 -n tekton-pipelines >/dev/null 2>&1 &
            sleep 5
        fi
    done
}

function forward_provisioner() {
    while true; do
        POD_NAME=$(kubectl get pods --namespace tekton-tasks -l "app.kubernetes.io/name=platform-provisioner-ui,app.kubernetes.io/instance=platform-provisioner-ui" -o jsonpath="{.items[0].metadata.name}")
        CONTAINER_PORT=$(kubectl get pod --namespace tekton-tasks $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
        if pgrep -f "kubectl.*port-forward.*$POD_NAME.*8080:$CONTAINER_PORT" >/dev/null; then
            sleep 5
        else
            echo "Restarting port-forward for provisioner UI (8080)"
            nohup kubectl --namespace tekton-tasks port-forward $POD_NAME 8080:$CONTAINER_PORT >/dev/null 2>&1 &
            sleep 5
        fi
    done
}

case $1 in
    "tekton")
        forward_tekton &
        ;;
    "provisioner")
        forward_provisioner &
        ;;
    "ingress")
        forward_ingress &
        ;;
    "all")
        echo "Enabling all port-forwards"
        forward_provisioner &
        forward_tekton &
        forward_ingress &
        wait
        ;;
    *)
        echo "Incorrect value provided"
        echo "Valid values: tekton, provisioner, ingress, all"
        echo "."
        ;;
esac
