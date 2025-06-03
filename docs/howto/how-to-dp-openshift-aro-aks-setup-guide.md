# How to Set Up Azure Red Hat OpenShift (ARO) Cluster and Deploy TIBCO Platform Data Plane

## Original documentation can be found and referred in future here: 
[ARO docs from tp-helm-charts](https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/docs/workshop/aro%20(Azure%20Red%20Hat%20OpenShift))

## Table of Contents
<!-- TOC -->
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Using a Prebuilt Docker Container for CLI Tools](#using-a-prebuilt-docker-container-for-cli-tools)
- [Step 1: Prepare Azure Environment](#step-1-prepare-azure-environment)
- [Step 2: Create Networking Resources](#step-2-create-networking-resources)
- [Step 3: Create ARO Cluster](#step-3-create-aro-cluster)
- [Step 4: Permissions and Role Assignments](#step-4-permissions-and-role-assignments)
- [Step 5: Connect to the Cluster](#step-5-connect-to-the-cluster)
- [Step 6: Configure Security Context Constraints](#step-6-configure-security-context-constraints)
- [Step 7: Prepare Data Plane Environment](#step-7-prepare-data-plane-environment)
- [Step 8: Install Storage Classes](#step-8-install-storage-classes)
- [Step 9: Configure Observability](#step-9-configure-observability)
- [Step 10: Deploy TIBCO Platform Data Plane](#step-10-deploy-tibco-platform-data-plane)
- [Step 11: Provision TIBCO BWCE and Flogo Capabilities from the GUI](#step-11-provision-tibco-bwce-and-flogo-capabilities-from-the-gui)
- [Step 12: Clean Up](#step-12-clean-up)
- [References](#references)
- [Troubleshooting and Cluster Information Commands](#troubleshooting-and-cluster-information-commands)
<!-- TOC -->

---

## Introduction

This guide provides step-by-step instructions to set up an Azure Red Hat OpenShift (ARO) cluster and deploy the TIBCO Platform Data Plane on it. It is intended for workshop and evaluation purposes, **not for production**.

---

## Prerequisites

- **Azure Subscription** with Owner or Contributor + User Access Administrator roles.
- **Red Hat account** for pull secret.
- **Command-line tools** (install via [Homebrew](https://brew.sh/)):
    - `az` (Azure CLI)
    - `oc` (OpenShift CLI)
    - `kubectl`
    - `helm`
    - `jq`, `yq`, `envsubst`, `bash`
- **Docker** (optional, for containerized CLI tools)
- **TIBCO Platform Helm charts repo**: [https://tibcosoftware.github.io/tp-helm-charts](https://tibcosoftware.github.io/tp-helm-charts)

---

## Clone tp-helm-charts repo

To clone the `tp-helm-charts` repository, run:

```bash
git clone https://github.com/TIBCOSoftware/tp-helm-charts.git
cd tp-helm-charts
```

This will download the latest charts and scripts required for the setup.

## Using a Prebuilt Docker Container for CLI Tools

All CLI commands in this guide can be executed inside a prebuilt Docker container that includes the required tools. This approach ensures a consistent environment and avoids local installation issues.

### Build the Docker Image

Navigate to the directory containing your Dockerfile (e.g., `/tp-helm-charts/docs/workshop`) and build the image:

```bash
docker buildx build --platform="linux/amd64" --progress=plain -t workshop-cli-tools:latest --load .
```

### Run the Container

Start an interactive shell with the necessary tools:

```bash
docker run -it --rm workshop-cli-tools:latest /bin/bash
```

> **Tip:** Mount your working directory with `-v $(pwd):/workspace` if you need access to local files inside the container.

All subsequent commands in this guide can be run from within this container shell.

---

## Step 1: Prepare Azure Environment

### 1.1. Export Required Variables

```bash
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TP_TENANT_ID=$(az account show --query tenantId -o tsv)
export TP_AZURE_REGION="westeurope" # or your preferred region
export TP_RESOURCE_GROUP="kul-atsbnl-flogo-azfunc"
export TP_CLUSTER_NAME="aroCluster"
export TP_WORKER_COUNT=6
export TP_VNET_NAME="openshiftvnet"
export TP_MASTER_SUBNET_NAME="masterOpenshiftSubnet"
export TP_WORKER_SUBNET_NAME="workerOpenshiftSubnet"
export TP_VNET_CIDR="10.0.0.0/8"
export TP_MASTER_SUBNET_CIDR="10.17.0.0/23"
export TP_WORKER_SUBNET_CIDR="10.17.2.0/23"
export TP_WORKER_VM_SIZE="Standard_D8s_v5"
export TP_WORKER_VM_DISK_SIZE_GB="128"
```

### 1.2. Login and Set Subscription

```bash
az login
az account set --subscription ${TP_SUBSCRIPTION_ID}
```

### 1.3. Register Required Resource Providers

```bash
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait
```

### 1.4. Download Red Hat Pull Secret

- Download from: https://console.redhat.com/openshift/install/azure/aro-provisioned
- Save as `pull-secret.txt` and set permissions:

```bash
chmod +x pull-secret.txt
```

---

## Step 2: Create Networking Resources

Navigate to your scripts directory and run the pre-cluster script:

```bash
cd "aro (Azure Red Hat OpenShift)/scripts"
./pre-aro-cluster-script.sh
```

This creates the resource group, VNet, and subnets.

---

## Step 3: Create ARO Cluster

```bash
az aro create \
    --resource-group ${TP_RESOURCE_GROUP} \
    --name ${TP_CLUSTER_NAME} \
    --vnet ${TP_VNET_NAME} \
    --master-subnet ${TP_MASTER_SUBNET_NAME} \
    --worker-subnet ${TP_WORKER_SUBNET_NAME} \
    --worker-count ${TP_WORKER_COUNT} \
    --worker-vm-disk-size-gb ${TP_WORKER_VM_DISK_SIZE_GB} \
    --worker-vm-size ${TP_WORKER_VM_SIZE} \
    --pull-secret @pull-secret.txt
```

Cluster creation takes 30–45 minutes.

---

## Step 4: Permissions and Role Assignments

Below are the key commands used to set permissions and roles for your ARO cluster and TIBCO Platform Data Plane setup, with brief descriptions for each step.

### 4.1. Set Resource Group Permissions

The ARO service principal requires `listKeys` permission on the Azure storage account resource group. Assign the Contributor role to the ARO service principal:

```bash
# Set environment variables
export ARO_RESOURCE_GROUP=kul-atsbnl-flogo-azfunc
export CLUSTER=aroCluster
export AZURE_FILES_RESOURCE_GROUP=kul-atsbnl-flogo-azfunc

# Get the ARO service principal ID
ARO_SERVICE_PRINCIPAL_ID=$(az aro show -g $ARO_RESOURCE_GROUP -n $CLUSTER --query servicePrincipalProfile.clientId -o tsv)

# Assign Contributor role to the ARO service principal on the storage resource group
az role assignment create --role Contributor --scope /subscriptions/$TP_SUBSCRIPTION_ID/resourceGroups/$AZURE_FILES_RESOURCE_GROUP --assignee $ARO_SERVICE_PRINCIPAL_ID
```
*Assigns necessary permissions for ARO to manage Azure Files storage resources.*

### 4.2. Set ARO Cluster Permissions

The OpenShift persistent volume binder service account requires permission to read secrets. Create and assign a custom cluster role:

```bash
# Get the ARO API server endpoint
ARO_API_SERVER=$(az aro list --query "[?contains(name,'$CLUSTER')].[apiserverProfile.url]" -o tsv)

# Login to the OpenShift cluster as kubeadmin
oc login -u kubeadmin -p $(az aro list-credentials -g $ARO_RESOURCE_GROUP -n $CLUSTER --query=kubeadminPassword -o tsv) $ARO_API_SERVER

# Create a cluster role to allow reading secrets
oc create clusterrole azure-secret-reader \
    --verb=create,get \
    --resource=secrets

# Assign the cluster role to the persistent-volume-binder service account
oc adm policy add-cluster-role-to-user azure-secret-reader system:serviceaccount:kube-system:persistent-volume-binder
```
*Enables OpenShift to bind persistent volumes by granting the required permissions to read secrets.*

---

## Step 5: Connect to the Cluster

### 5.1. Get Credentials

```bash
az aro list-credentials --name ${TP_CLUSTER_NAME} --resource-group ${TP_RESOURCE_GROUP}
```

### 5.2. Login with OpenShift CLI

```bash
apiServer=$(az aro show -g ${TP_RESOURCE_GROUP} -n ${TP_CLUSTER_NAME} --query apiserverProfile.url -o tsv)
oc login ${apiServer} -u <kubeadminUsername> -p <kubeadminPassword>
```

### 5.3. Access OpenShift Console

```bash
az aro show --name ${TP_CLUSTER_NAME} --resource-group ${TP_RESOURCE_GROUP} --query "consoleProfile.url" -o tsv
```

---

## Step 6: Configure Security Context Constraints

Create a custom SCC for TIBCO workloads:

```bash
oc apply -f - <<EOF
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
    name: tp-scc
priority: 10
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: false
allowPrivilegedContainer: false
allowedCapabilities:
- NET_BIND_SERVICE
fsGroup:
    type: RunAsAny
readOnlyRootFilesystem: false
requiredDropCapabilities:
- ALL
runAsUser:
    type: RunAsAny
seLinuxContext:
    type: MustRunAs
seccompProfiles:
- runtime/default
supplementalGroups:
    type: RunAsAny
volumes:
- configMap
- csi
- downwardAPI
- emptyDir
- ephemeral
- persistentVolumeClaim
- projected
- secret
EOF
```

Verify:

```bash
oc get scc tp-scc
```

---

## Step 7: Prepare Data Plane Environment

Set additional variables:

```bash
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts
```

---

## Step 8: Install Storage Classes

### 8.1. Azure Files Storage Class

```bash
oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
allowVolumeExpansion: true
kind: StorageClass
metadata:
    name: azure-files-sc
mountOptions:
- mfsymlinks
- cache=strict
- nosharesock
parameters:
    allowBlobPublicAccess: "false"
    networkEndpointType: privateEndpoint
    skuName: Premium_LRS
provisioner: file.csi.azure.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
EOF
```

### 8.2. Azure Files (NFS) for EMS

```bash
oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
allowVolumeExpansion: true
kind: StorageClass
metadata:
    name: azure-files-sc-ems
mountOptions:
- soft
- timeo=300
- actimeo=1
- retrans=2
- _netdev
parameters:
    allowBlobPublicAccess: "false"
    networkEndpointType: privateEndpoint
    protocol: nfs
    skuName: Premium_LRS
provisioner: file.csi.azure.com
reclaimPolicy: Retain
volumeBindingMode: Immediate
EOF
```

### 8.3. Azure Disk Storage Class

```bash
oc apply -f - <<EOF
apiVersion: storage.k8s.io/v1
allowVolumeExpansion: true
kind: StorageClass
metadata:
    name: azure-disk-sc
parameters:
    skuName: Premium_LRS
provisioner: disk.csi.azure.com
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
EOF
```

---

## Step 9: Configure Observability

### 9.1. Elastic Stack

Install ECK via OperatorHub:  
[Elastic ECK on OpenShift](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/deploy-eck-on-openshift)

### 9.2. Prometheus

Prometheus is pre-installed. To scrape metrics from Data Plane, create a ServiceMonitor:

```bash
export DP_NAMESPACE="dp1" # Replace with your namespace
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
    name: otel-collector-monitor
    namespace: ${DP_NAMESPACE}
spec:
    endpoints:
    - interval: 30s
      path: /metrics
      port: prometheus
      scheme: http
    jobLabel: otel-collector
    selector:
      matchLabels:
        app.kubernetes.io/name: otel-userapp-metrics
EOF
```

To access Prometheus externally, use a service account token:

```bash
oc create sa thanos-client -n openshift-monitoring 
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z thanos-client -n openshift-monitoring
TOKEN=$(oc create token thanos-client -n openshift-monitoring)
```

---

## Step 10: Deploy TIBCO Platform Data Plane

Login to your SaaS CP and Register a new Data plane. 
Follow the wizard which will generate following helm commands with a unique DP ID. 

Dataplane name: aroCluster or aroDataplane or aroStaging
Dataplane k8s namespace: dp1

### 10.1. Add Helm Repo

```bash
helm repo add tibco-platform-public https://tibcosoftware.github.io/tp-helm-charts
helm repo update tibco-platform-public
```

### 10.2. Create Namespace

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: dp1
    labels:
        platform.tibco.com/dataplane-id: <your-dataplane-id>
EOF
```

### 10.3. Configure Namespace

```bash
helm upgrade --install -n dp1 dp-configure-namespace tibco-platform-public/dp-configure-namespace \
    --version 1.7.5 \
    --set global.tibco.dataPlaneId=<your-dataplane-id> \
    --set global.tibco.subscriptionId=<your-subscription-id> \
    --set global.tibco.primaryNamespaceName=dp1 \
    --set global.tibco.serviceAccount=sa \
    --set global.tibco.containerRegistry.url=<your-registry-url> \
    --set global.tibco.containerRegistry.username=<your-registry-username> \
    --set global.tibco.containerRegistry.password=<your-registry-password> \
    --set global.tibco.containerRegistry.repository=tibco-platform-docker-prod \
    --set global.tibco.enableClusterScopedPerm=true \
    --set networkPolicy.createDeprecatedPolicies=false
```

### 10.4. Deploy Core Infrastructure

```bash
helm upgrade --install dp-core-infrastructure -n dp1 tibco-platform-public/dp-core-infrastructure \
    --version 1.7.2 \
    --set global.tibco.dataPlaneId=<your-dataplane-id> \
    --set global.tibco.subscriptionId=<your-subscription-id> \
    --set tp-tibtunnel.configure.accessKey=<your-access-key> \
    --set tp-tibtunnel.connect.url=<your-tibtunnel-url> \
    --set global.tibco.serviceAccount=sa \
    --set global.tibco.containerRegistry.url=<your-registry-url> \
    --set global.tibco.containerRegistry.repository=tibco-platform-docker-prod \
    --set global.proxy.noProxy='' \
    --set global.logging.fluentbit.enabled=true
```

---

## Step 11: Provision TIBCO BWCE and Flogo Capabilities from the GUI

Once the Data Plane is registered and core infrastructure is deployed, you can provision additional capabilities such as TIBCO BusinessWorks Container Edition (BWCE) and TIBCO Flogo directly from the TIBCO Control Plane GUI.

### Steps:

1. **Login to TIBCO Control Plane (SaaS GUI):**
    - Navigate to your TIBCO Control Plane URL and sign in.

2. **Select Your Data Plane:**
    - Go to the "Data Planes" section and select the Data Plane you registered and deployed.

3. **Add Capabilities:**
    - Click on "Provision a Capability".
    - Choose **TIBCO BusinessWorks Container Edition (BWCE)** or **TIBCO Flogo** from the list and press Start button
    - Configure storage class azure-files-sc for Flogo and/or BWCE
    - For ingress: use the base URL and prefix it with `flogo.` or `bwce.`. You can find the base URL using [Get OpenShift Ingress Domain](#get-openshift-ingress-domain).
    - Follow the wizard to configure other required parameters
    - Once finished you will see BWCE and/or Flogo Capability provisioned

4. **Monitor Deployment:**
    - The Control Plane will show the capability provisioning/deployment status.
    - You can monitor progress and logs from the GUI or by checking pods in the corresponding namespace:

    ```bash
    oc -n dp1 get pods
    ```
5. **Deploy apps**
    - Now you can deploy the apps. Follow the documentation of BWCE or Flogo in case you are not aware of how to build your first project and deploy it to TIBCO Platform

> **Note:** The Control Plane GUI automates the Helm chart installation and configuration for these capabilities. No manual CLI steps are required for this process.

--- 

---

## Step 12: Clean Up

- Delete Data Plane from TIBCO Control Plane UI.
- Run cleanup script:

```bash
cd ../scripts
./clean-up.sh
```

---

## References

- [Azure ARO Documentation](https://learn.microsoft.com/en-us/azure/openshift/)
- [TIBCO Platform Helm Charts](https://tibcosoftware.github.io/tp-helm-charts)
- [Elastic ECK on OpenShift](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/deploy-eck-on-openshift)
- [OpenShift Monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/accessing-metrics)

---

> **Note:** Adjust all placeholder values (e.g., `<your-dataplane-id>`, `<your-registry-url>`) as per your environment and TIBCO Control Plane configuration.

---

## Troubleshooting and Cluster Information Commands

This section provides useful commands for troubleshooting, monitoring, and inspecting your Azure Red Hat OpenShift (ARO) cluster and deployed workloads.

### List All ARO Clusters in a Subscription

```bash
az aro list -o table
```
*Displays all Azure Red Hat OpenShift clusters in your current subscription.*

### Show Details for a Specific ARO Cluster

```bash
az aro show --resource-group ${TP_RESOURCE_GROUP} --name ${TP_CLUSTER_NAME}
```
*Shows detailed information about a specific ARO cluster.*

### Get ARO Cluster Credentials

```bash
az aro list-credentials --name ${TP_CLUSTER_NAME} --resource-group ${TP_RESOURCE_GROUP}
```
*Retrieves the kubeadmin credentials for your ARO cluster.*

### View and Verify Environment Variables

```bash
env | grep TP
```
*Shows all environment variables related to your deployment.*

### Get OpenShift Ingress Domain

```bash
oc get ingresscontroller -n openshift-ingress-operator default -o json | jq -r '.status.domain'
```
*Displays the default ingress domain for your OpenShift cluster.*
### Check Cluster Resources and Status

```bash
oc get ns
oc get pods -A
oc get deploy -A
oc get crds -A
oc get sc
oc get ingress -A
oc get storageaccounts
```
*Lists namespaces, pods, deployments, custom resources, storage classes, ingresses, and storage accounts.*

### Inspect Security Context Constraints (SCC)

```bash
oc get securitycontextconstraints.security.openshift.io
oc get scc tp-scc -o wide
```
*Lists all SCCs and details for the custom `tp-scc`.*

### Monitor Events and Pod Status

```bash
oc get events -w
kubectl get events --sort-by='.metadata.creationTimestamp' -n dp1 --watch
oc -n dp1 get pods -w
```
*Watches for real-time events and pod status changes in the `dp1` namespace.*

### View Logs for Troubleshooting

```bash
oc -n dp1 logs <pod-name>
oc -n dp1 logs -c <container-name> <pod-name>
```
*Fetches logs from a pod or a specific container within a pod.*

---

These commands help you quickly inspect, troubleshoot, and monitor your ARO cluster and TIBCO Platform Data Plane deployment.

