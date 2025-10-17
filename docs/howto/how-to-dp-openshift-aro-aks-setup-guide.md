# How to Set Up Azure Red Hat OpenShift (ARO) Cluster and Deploy TIBCO Platform Data Plane

## Original documentation can be found and referred in future here: 
[ARO docs from tp-helm-charts](https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/docs/workshop/aro%20(Azure%20Red%20Hat%20OpenShift))

This document is with extra details while following the above document and make all the things working. 

Note: This document is copy of gh-pages doc from [here:](https://tibco-bnl.github.io/workshop-tibco-platform/docs/howto/how-to-dp-openshift-aro-aks-setup-guide.html#get-openshift-ingress-domain) hence links in table of contents will not work if you are viewing in google docs. 

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

This will download the latest charts and scripts required for the setup. Cloning this repository is essential as it contains the Helm charts and scripts specifically designed for deploying TIBCO Platform on Kubernetes environments, ensuring you have access to all required deployment components.

## Using a Prebuilt Docker Container for CLI Tools

All CLI commands in this guide can be executed inside a prebuilt Docker container that includes the required tools. This approach ensures a consistent environment and avoids local installation issues.

### Why use a Docker container?
Using a container provides several benefits:
- Ensures all CLI tools are at the correct versions without conflicts
- Eliminates the need to install and configure multiple tools locally
- Creates a reproducible environment that works consistently across different operating systems
- Avoids potential issues with local tool configurations or missing dependencies

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

This step creates the foundation for your ARO deployment by setting necessary environment variables and ensuring your Azure subscription is properly configured.

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

We set these environment variables to streamline the deployment process and maintain consistency throughout the configuration. The worker count, VM size, and disk sizes are selected to ensure adequate resources for running TIBCO Platform workloads effectively.

### 1.2. Login and Set Subscription

```bash
az login
az account set --subscription ${TP_SUBSCRIPTION_ID}
```

This ensures you're working with the correct Azure subscription for all subsequent operations.

### 1.3. Register Required Resource Providers

```bash
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait
```

These registrations are necessary because ARO requires specific Azure resource providers to manage compute resources, storage, and permissions. Without registering these providers, the ARO deployment would fail.

### 1.4. Download Red Hat Pull Secret

- Download from: https://console.redhat.com/openshift/install/azure/aro-provisioned
- Save as `pull-secret.txt` and set permissions:

```bash
chmod +x pull-secret.txt
```

The pull secret is required for ARO to authenticate with Red Hat's container registries and access the necessary OpenShift container images during installation and updates. Without this, the cluster cannot pull required images.

---

## Step 2: Create Networking Resources

Navigate to your scripts directory and run the pre-cluster script:

This script prepares the Azure environment (resource group, VNet, subnets) needed before deploying an ARO cluster, ensuring all required network infrastructure is in place.

E.g. It creates openshiftvnet with master and worker subnets.

```bash
cd "aro (Azure Red Hat OpenShift)/scripts"
./pre-aro-cluster-script.sh
```

This step is crucial because ARO requires a specific networking setup with segregated subnets for master and worker nodes. The script automates this complex networking configuration to ensure proper communication between cluster components while maintaining security through network isolation.

---

## Step 3: Create ARO Cluster

Cluster creation takes 30–45 minutes.

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

This command creates an Azure Red Hat OpenShift cluster with the specified configuration. The worker node count, size, and disk space are important parameters as they determine the cluster's capacity to run TIBCO Platform workloads. The pull secret enables the cluster to authenticate with Red Hat's container registry to download the required OpenShift images.

---

## Step 4: Permissions and Role Assignments

Below are the key commands used to set permissions and roles for your ARO cluster and TIBCO Platform Data Plane setup, with brief descriptions for each step.

Ref: [Microsoft ARO Doc: How to Create a Storage Class and Set Permissions](https://learn.microsoft.com/en-us/azure/openshift/howto-create-a-storageclass#set-permissions)

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

This step is essential because without these permissions, the ARO cluster would be unable to create and manage Azure storage resources like file shares needed by the TIBCO Platform for persistent storage.

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

This permission configuration is critical because Kubernetes persistent volumes often require secret access to authenticate with external storage providers. Without these permissions, the OpenShift cluster would fail to properly provision storage for TIBCO Platform components.

---

## Step 5: Connect to the Cluster

### 5.1. Get Credentials

You can also get credentials from the aroCluster in Azure Portal by clicking on "Connect" button. 

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

Connecting to your cluster is necessary to begin configuring OpenShift-specific resources and deploying applications. The different connection methods (CLI and web console) provide flexibility for different administrative tasks - CLI access is essential for automation and scripting, while the web console provides a visual interface for cluster management.

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

This custom Security Context Constraint is necessary because OpenShift enforces strict security policies by default. The TIBCO Platform requires specific permissions (like running as non-root users with specific UIDs) that aren't available in the default SCCs. This custom SCC provides the minimal privileges required for TIBCO applications to function properly without compromising the cluster's security posture.

---

## Step 7: Prepare Data Plane Environment

Set additional variables (if you are still in the same terminal window, else export all the env variables again):

```bash
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts
```


### Ingress Controller & DNS

#### Ingress Controller
For the purpose of this data plane workshop, we are using the default ingress controller available with the ARO cluster.
Please refer to [ARO Ingress Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/networking/configuring-ingress#nw-ne-openshift-ingress_configuring-ingress)

Use the following command to get the ingress class name.
```bash
oc get ingressclass -A
NAME                            CONTROLLER                                                     PARAMETERS                                        AGE
openshift-default               openshift.io/ingress-to-route                                  IngressController.operator.openshift.io/default   39d
```

If you are using network policies, to ensure that network traffic is allowed from the default ingress namespace to the Data Plane namespace pods, label the namespace running following command

```bash
oc label namespace openshift-ingress networking.platform.tibco.com/non-dp-ns=enable --overwrite=true
```

This labeling is important because TIBCO Platform uses network policies to restrict traffic between namespaces for security. By labeling the ingress namespace, we explicitly allow traffic from the ingress controller to the Data Plane pods, ensuring applications remain accessible while maintaining security boundaries.

### DNS
For the purpose of this data plane workshop, we are using default DNS provisioned for ARO cluster. The base DNS of this can be found using the following command

```bash
oc get ingresscontroller -n openshift-ingress-operator default -o json | jq -r '.status.domain'
```
It should be something like "apps.<random_alphanumeric_string>.${TP_AZURE_REGION}.aroapp.io"

Determining the base domain is crucial because all application routes and ingresses will use this domain. TIBCO Platform capabilities like Flogo and BWCE need to be exposed through specific subdomains of this base domain to be accessible from outside the cluster.

---

## Step 8: Install Storage Classes

### 8.1. Azure Files Storage Class (Used in capabilities)

You will require the storage classes for capabilities deployment.
Run the following command to create a storage class which uses Azure Files (Persistent Volumes will be created as fileshares).

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

Storage classes are essential because TIBCO Platform capabilities require persistent storage for configurations, logs, and application data. Using Azure Files provides a managed file storage solution that works well with multi-pod deployments that need shared access to the same files. The mount options are specifically configured to ensure optimal performance and compatibility with TIBCO applications.

### 8.2. Azure Files for EMS
For TIBCO Enterprise Message Service™ (EMS) capability, you will need to create one of the following two storage classes:
Run the following command to create a storage class with nfs protocol which uses Azure Files

#### With NFS

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

EMS requires NFS storage because it provides file-level locking capabilities that are essential for the message store. The specific mount options optimize NFS behavior for enterprise messaging workloads, ensuring data consistency and reliability.

#### Without NFS 
Alternatively, run the following command to create a storage class with Azure Disks

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

Azure Disk provides an alternative storage option with better performance for single-instance deployments. The "WaitForFirstConsumer" binding mode ensures that persistent volumes are only created when pods request them, which helps with pod scheduling efficiency across availability zones.

---
## Grant Privileged SCC to Service Accounts

To ensure certain workloads have the necessary permissions, grant the `privileged` Security Context Constraint (SCC) to the default and `sa` service accounts in the `dp1` namespace:

```bash
oc adm policy add-scc-to-user privileged -z default -n dp1
oc adm policy add-scc-to-user privileged -z sa -n dp1
```

*This step allows pods running under these service accounts to use the `privileged` SCC, which may be required for some TIBCO Platform components.*

This permission assignment is necessary because some TIBCO Platform components need elevated privileges to perform specific operations like binding to lower-numbered ports or modifying certain system settings. Without these permissions, these components would fail to start or function correctly.

## Step 9: Configure Observability

Note 1: This is optional because if you already have your observability stack we can configure to use yours.
For logs and traces DP needs Elastic. 
For metrics DP needs prometheus

Note 2: You can also configure observability after creating/registering the Data Plane.

### 9.1. Elastic Stack

Install ECK via OperatorHub:  
[Elastic ECK on OpenShift](https://www.elastic.co/docs/deploy-manage/deploy/cloud-on-k8s/deploy-eck-on-openshift)

Follow Elastic configuration guide for creating all the indexes needed for the TIBCO Platform
[Prepare logs and traces server](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Default.htm#UserGuide/preparing-logs-and-traces-servers.htm?TocPath=Observability%2520in%2520TIBCO%2520Control%2520Plane%257CConfiguring%2520Observability%2520Resource%257C_____1)

Observability is critical for TIBCO Platform because it provides visibility into application performance, troubleshooting capabilities, and monitoring of business metrics. The Elastic Stack handles logs and traces, giving you insight into application behavior and performance issues.

### 9.2. Prometheus

**Note:** There is already a prometheus provisioned in the ARO cluster. For DP we will provision our own prometheus in the namespace mentioned below. 

Prometheus is pre-installed. To scrape metrics from Data Plane, create a ServiceMonitor:

```
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

The ServiceMonitor is necessary because it configures Prometheus to automatically discover and scrape metrics from TIBCO Platform components. This metrics collection is essential for monitoring system health, resource usage, and application performance, allowing proactive identification of issues before they affect users.

To access inbuilt ARO Prometheus externally, use a service account token:

```markdown
To access Prometheus externally, you can create a dedicated service account with the necessary permissions. The following example uses a service account named `thanos-client`, which is a common convention when integrating with Thanos or other external monitoring tools, but you can use any name you prefer:

```bash
oc create sa thanos-client -n openshift-monitoring 
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z thanos-client -n openshift-monitoring
TOKEN=$(oc create token thanos-client -n openshift-monitoring)
```

- `thanos-client` is simply a service account name; it does not require Thanos to be installed. This account is granted the `cluster-monitoring-view` role, allowing it to access Prometheus metrics.
- The generated token (`$TOKEN`) can be used to authenticate with Prometheus endpoints for external scraping or dashboard access.
```

External access to Prometheus is valuable for integrating with existing enterprise monitoring systems and creating custom dashboards for business-specific metrics outside the OpenShift console.

---

## Step 10: Deploy TIBCO Platform Data Plane

Login to your SaaS CP and Register a new Data plane. 

**Note:** If you do not have an access to SaaS CP assigned to your customer work with TIBCO ATS Team.
Usually there is an invitation email sent to the manager or account lead. 

Follow the wizard which will generate following helm commands with a unique DP ID. 

Dataplane name: aroCluster or aroDataplane or aroStaging
Dataplane k8s namespace: dp1

### 10.1. Add Helm Repo

```bash
helm repo add tibco-platform-public https://tibcosoftware.github.io/tp-helm-charts
helm repo update tibco-platform-public
```

Adding the TIBCO Helm repository gives you access to the official, tested, and supported Helm charts for deploying TIBCO Platform components. This ensures you're using configurations that have been verified to work together.

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

Creating a dedicated namespace isolates TIBCO Platform resources from other applications on the cluster, providing better security, resource management, and organizational clarity. The dataplane-id label is crucial for the Control Plane to identify and manage this specific Data Plane instance.

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

This namespace configuration is necessary to set up service accounts, roles, and network policies that secure the TIBCO Platform deployment. It also configures access to the container registry, which is essential for pulling TIBCO container images during deployment.

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

The core infrastructure deployment installs essential components that enable communication between the Data Plane and Control Plane, including the tibtunnel component which creates a secure connection channel. This infrastructure is foundational for all TIBCO Platform operations in the cluster, such as application deployment, monitoring, and management.

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

Using the GUI for capability provisioning is advantageous because it simplifies the complex deployment process, ensures proper configuration with the Control Plane, and provides centralized management of all TIBCO Platform components. The GUI also offers built-in validation and simplified upgrades compared to manual Helm installations.

--- 

---

## Step 12: Clean Up

- Delete Data Plane from TIBCO Control Plane UI.
- Run cleanup script:

```bash
cd ../scripts
./clean-up.sh
```

Proper cleanup is important to avoid unnecessary Azure costs, as ARO clusters can be expensive to run. The cleanup script ensures that all resources are properly removed, preventing orphaned resources that might continue to incur charges.

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


