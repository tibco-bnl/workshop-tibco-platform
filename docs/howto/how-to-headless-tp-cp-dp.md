In Windows WSL install docker without GUI (stop the Windows Docker desktop)

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

Run minikube

minikube start --cpus=max   --memory "20g" --disk-size "40g"   --driver=docker   --embed-certs   --listen-add
ress='0.0.0.0'   --addons storage-provisioner   --kubernetes-version v1.32.0

Donwload headless public script

# set 4 to adjust recipe for minikube 
export TP_K8S_CLUSTER_TYPE_CODE=4

# set 1 to use nginx set 2 to use traefik
export TP_K8S_INGRESS_TYPE_CODE=1

Run the headless script
./headless-tp-install-public.sh

Or Run the public Platform provisioner which is exactly same as the headless script
Reference: https://github.com/TIBCOSoftware/platform-provisioner/tree/main/docs/recipes/k8s/on-prem
And in this also needs more env variables to be setup and you must create your own certificates and have Control Plane JFrog container registry credentials 

export GUI_TP_TLS_CERT=""
export GUI_TP_TLS_KEY=""

export GUI_CP_CONTAINER_REGISTRY: csgprduswrepoedge.jfrog.io
export GUI_CP_CONTAINER_REGISTRY_REPOSITORY: tibco-platform-docker-prod
export GUI_CP_CONTAINER_REGISTRY_USERNAME=""
export GUI_CP_CONTAINER_REGISTRY_PASSWORD=""

./tp-install-on-prem.sh
