


# Setting Up and Configuring Azure Kubernetes Service (AKS) for TIBCO Platform Data Plane

> **Reference:** [Main source for this guide](https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/docs/workshop/aks/data-plane)

This guide walks you through setting up and configuring an Azure Kubernetes Service (AKS) cluster as a TIBCO Platform Data Plane. It covers prerequisites, cluster creation, and installation of required tools and components.

## Table of Contents


- [1. Prerequisites](#1-prerequisites)
- [2. Clone the tp-helm-charts Repository](#2-clone-the-tp-helm-charts-repository)
- [3. Using a Prebuilt Docker Container for CLI Tools (Optional)](#3-using-a-prebuilt-docker-container-for-cli-tools-optional)
- [4. Export Required Variables](#4-export-required-variables)
- [5. Create the AKS Cluster](#5-create-the-aks-cluster)
- [6. Install Third-Party Tools](#6-install-third-party-tools)
- [7. Install Observability Tools](#7-install-observability-tools)
- [8. Information for TIBCO Data Plane Configuration](#8-information-for-tibco-data-plane-configuration)
- [](#99: Deploy TIBCO Platform Data Plane)
- [9. Cleanup](#9-cleanup)

-----

## 1. Prerequisites

Before you begin, ensure you have the following:  
(Alternatively you can jump to step 3 and run everything from a docker image.)

* **Azure Subscription:** With `Owner` or `Contributor` + `User Access Administrator` roles
* **Red Hat Account:** For pull secret
* **Command-line Tools:** Install via [Homebrew](https://brew.sh/) (macOS/Linux):
  * `az` (Azure CLI)
  * `kubectl`
  * `helm`
  * `jq`, `yq`, `envsubst`, `bash`
* **Docker:** (Optional) For containerized CLI tools
* **TIBCO Platform Helm Charts Repository:** `https://tibcosoftware.github.io/tp-helm-charts`


## 2. Clone the tp-helm-charts Repository

Clone the repository containing all necessary charts and scripts:

```bash
git clone https://github.com/TIBCOSoftware/tp-helm-charts.git
cd tp-helm-charts
```


## 3. Using a Prebuilt Docker Container for CLI Tools (Optional)

To ensure a consistent environment and avoid local installation issues, use a prebuilt Docker container with all required CLI tools.

### Build the Docker Image

Navigate to the directory containing the Dockerfile (e.g., `/tp-helm-charts/docs/workshop`) and build the image:

```bash
docker buildx build --platform="linux/amd64" --progress=plain -t workshop-cli-tools:latest --load .
```

### Run the Container

Start an interactive shell within the container:

```bash
docker run -it --rm workshop-cli-tools:latest /bin/bash
```


> **Tip:** To access local files inside the container, mount your working directory: `-v $(pwd):/workspace`

All subsequent commands in this guide can be run from within this container shell.


## 4. Export Required Variables

Before running setup scripts, set the following environment variables. Scripts and configurations rely on these values. Prefix: `TP_` (TIBCO PLATFORM).


> **Note:** We use `az` CLI commands to create prerequisites and the cluster. Review and set the variables below correctly.

### Azure Specific Variables

#### For using them from script: 
- Use script: [aks-aks-env-variables.sh](aks-aks-env-variables.sh)

```bash
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv) # subscription id
export TP_TENANT_ID=$(az account show --query tenantId -o tsv) # tenant id
export TP_AZURE_REGION="westeurope" # region of resource group
```

### Cluster Configuration Specific Variables

```bash
export TP_RESOURCE_GROUP="kul-atsbnl" # set the resource group name in which all resources will be deployed
export TP_CLUSTER_NAME="dp1-aks-aauk-kul" # name of the cluster to be provisioned
export TP_KUBERNETES_VERSION="1.32.6" # refer to: https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
export TP_USER_ASSIGNED_IDENTITY_NAME="${TP_CLUSTER_NAME}-identity" # user assigned identity to be associated with the cluster

#Uncomment if you are running from docker image but nevertheless this is optional
#export KUBECONFIG=`pwd`/${TP_CLUSTER_NAME}.yaml # kubeconfig file path
```

### Network Specific Variables

```bash
export TP_VNET_NAME="${TP_CLUSTER_NAME}-vnet" # name of VNet resource
export TP_VNET_CIDR="10.4.0.0/16" # CIDR of the VNet
export TP_SERVICE_CIDR="10.0.0.0/16" # CIDR for service cluster IPs
export TP_SERVICE_DNS_IP="10.0.0.10" # IP address for the Kubernetes DNS service
export TP_AKS_SUBNET_NAME="${TP_CLUSTER_NAME}-aks-subnet" # name of AKS subnet
export TP_AKS_SUBNET_CIDR="10.4.0.0/20" # CIDR of the AKS subnet
export TP_APPLICATION_GW_SUBNET_NAME="appgw-subnet" # name of Application Gateway subnet
export TP_APPLICATION_GW_SUBNET_CIDR="10.4.17.0/24" # CIDR of the Application Gateway subnet
export TP_PUBLIC_IP_NAME="public-ip" # name of public IP resource
export TP_NAT_GW_NAME="nat-gateway" # name of NAT gateway resource
export TP_NAT_GW_SUBNET_NAME="natgw-subnet" # name of NAT gateway subnet
export TP_NAT_GW_SUBNET_CIDR="10.4.18.0/27" # CIDR of the NAT gateway subnet
export TP_APISERVER_SUBNET_NAME="apiserver-subnet" # name of API server subnet
export TP_APISERVER_SUBNET_CIDR="10.4.19.0/28" # CIDR of the API server subnet
export TP_NODE_VM_COUNT="3" # Number of VM nodes
export TP_NODE_VM_SIZE="Standard_D4s_v3" # VM Size of nodes
```

### Network Policy and Other Variables

```bash
export TP_NETWORK_POLICY="azure" # possible values: "azure", "calico", "none"
export TP_NETWORK_PLUGIN="azure" # possible values: "azure", "calico", "none"
export TP_AUTHORIZED_IP="" # whitelisted IP for accessing the cluster
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts # location of charts repo url
export TP_DNS_RESOURCE_GROUP="kul-atsbnl" # resource group for DNS record-sets
```

### Domain Specific Variables

```bash
# To use the same domain for services and user apps:
export TP_DOMAIN="dp1.kul.atsnl-emea.azure.dataplanes.pro"

# To use different domains for services and user apps [OPTIONAL]:
# export TP_DOMAIN="services.$TP_DOMAIN"
# export TP_APPS_DOMAIN="apps.$TP_DOMAIN"


export TP_SANDBOX="dp1" # hostname of TP_DOMAIN
export TP_TOP_LEVEL_DOMAIN="kul.atsnl-emea.azure.dataplanes.pro" # top level domain
#export TP_MAIN_INGRESS_CLASS_NAME="azure-application-gateway" # name of Azure Application Gateway Ingress Controller
export TP_MAIN_INGRESS_CLASS_NAME="nginx" # name of Azure Application Gateway Ingress Controller
export TP_DISK_ENABLED="true" # enables Azure Disk storage class
export TP_DISK_STORAGE_CLASS="azure-disk-sc" # name of Azure Disk storage class
export TP_FILE_ENABLED="true" # enables Azure Files storage class
export TP_FILE_STORAGE_CLASS="azure-files-sc" # name of Azure Files storage class
export TP_INGRESS_CLASS="nginx" # name of main ingress class
export TP_ES_RELEASE_NAME="dp-config-es" # name of dp-config-es release
export TP_STORAGE_ACCOUNT_NAME="" # replace with name of existing storage account (optional)
export TP_STORAGE_ACCOUNT_RESOURCE_GROUP="" # replace with name of storage account resource group (optional)
export DP_NAMESPACE="dp1"
```


## 5. Create the AKS Cluster

Before creating the cluster, log in to Azure and set the correct subscription:

```bash
az login
az account set --subscription ${TP_SUBSCRIPTION_ID}
```

### 5.1 Run Pre-requisite Scripts

Change the directory to `aks/scripts` and run the pre-requisite script.

```bash
cd aks/scripts
./pre-aks-cluster-script.sh
```

**Expected Output:** The console output should show a series of JSON objects, confirming the successful creation of the VNet and its subnets.

### 5.2 Enable Preview Features and Add Extension

Register the `EnableAPIServerVnetIntegrationPreview` feature and add the `aks-preview` extension. This is a one-time step.

```bash
az feature register --namespace "Microsoft.ContainerService" --name "EnableAPIServerVnetIntegrationPreview"
az extension add --name aks-preview
```

**Expected Output:** You should see a message indicating the feature is `Registered` and a warning that the `aks-preview` extension is in preview.

### 5.3 Run Cluster Creation Scripts

Run the `aks-cluster-create.sh` script to provision the AKS cluster.

```bash
./aks-cluster-create.sh
```

> The cluster creation process will take approximately 15 minutes.

**Expected Output:** The console output will show a large JSON object representing the newly created cluster. Important fields to note:

  * `provisioningState`: should be `Succeeded`.
  * `agentPoolProfiles`: confirms the number of nodes (`"count": 3`) and their size (`"vmSize": "Standard_D4s_v3"`).
  * `apiServerAccessProfile`: shows that VNet integration is enabled and your public IP is authorized.
  * `networkProfile`: confirms the `azure` network plugin and policy, as well as the `userAssignedNATGateway` outbound type.
  * `securityProfile`: confirms that `workloadIdentity` is enabled.

### 5.4 Run Post-Creation Scripts

After the cluster is created, run the `post-aks-cluster-script.sh` script. This script configures federated workload identity for `cert-manager` and `external-dns`, a crucial security step that allows these services to securely access Azure resources without storing secrets.

```bash
./post-aks-cluster-script.sh
```

**Expected Output:** The console will show JSON objects confirming the creation of federated identity credentials and the `azure-config-file` secret.

### 5.5 Connect to the Cluster

Generate the `kubeconfig` file and test the connection to your new AKS cluster:

```bash
az aks get-credentials --resource-group ${TP_RESOURCE_GROUP} --name ${TP_CLUSTER_NAME} --file "${KUBECONFIG}" --overwrite-existing
kubectl get nodes
```

**Expected Output:** `kubectl get nodes` should return a list of your three `Ready` nodes.


## 6. Install Third-Party Tools

Before deploying the TIBCO Platform Data Plane, install essential third-party tools: Cert Manager, External DNS, Ingress Controllers, and Storage Classes.


> **Note:** The `helm` commands use the `--labels layer=<number>` flag (Helm v3.13+), which helps identify chart dependencies for easier uninstallation.

### 6.1 Install Cert Manager

Install Cert Manager to handle TLS certificates automatically:

```bash
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n cert-manager cert-manager cert-manager \
  --labels layer=0 \
  --repo "https://charts.jetstack.io" --version "v1.17.1" -f - <<EOF
installCRDs: true
podLabels:
  azure.workload.identity/use: "true"
serviceAccount:
  labels:
    azure.workload.identity/use: "true"
EOF
```

**Expected Output:** You'll see a message that the `cert-manager` release has been successfully deployed.

### 6.2 Install External DNS

External DNS automatically creates DNS records for services and ingress resources in Azure DNS Zones.

```bash
helm upgrade --install --wait --timeout 1h --reuse-values \
  -n external-dns-system external-dns external-dns \
  --labels layer=0 \
  --repo "https://kubernetes-sigs.github.io/external-dns" --version "1.15.2" -f - <<EOF
provider: azure
sources:
  - service
  - ingress
domainFilters:
  - ${TP_DOMAIN}
extraVolumes: # for azure.json
- name: azure-config-file
  secret:
    secretName: azure-config-file
extraVolumeMounts:
- name: azure-config-file
  mountPath: /etc/kubernetes
  readOnly: true
extraArgs:
- --ingress-class=${TP_MAIN_INGRESS_CLASS_NAME}
- --txt-wildcard-replacement=wildcard 
EOF
```

### 6.3 Install Cluster Issuer, Ingress Controller and Storage Class

In this section, we will install cluster issuer, ingress controller and storage class. We have made a helm chart called `dp-config-aks` that encapsulates the installation of ingress controller and storage class.
It will create the following resources:
* cluster issuer to represent certificate authorities (CAs) that are able to generate signed certificates by honoring certificate signing requests
* ingress object which will be able to create Azure load balancer
* annotation for external-dns to create DNS record for the ingress
* storage class for Azure Disks
* storage class for Azure Files

### Install Cluster Issuer

```bash
export TP_CLIENT_ID=$(az aks show --resource-group "${TP_RESOURCE_GROUP}" --name "${TP_CLUSTER_NAME}" --query "identityProfile.kubeletidentity.clientId" --output tsv)

helm upgrade --install --wait --timeout 1h --create-namespace \
  -n ingress-system dp-config-aks-ingress-certificate dp-config-aks \
  --labels layer=1 \
  --repo "${TP_TIBCO_HELM_CHART_REPO}" --version "^1.0.0" -f - <<EOF
global:
  dnsSandboxSubdomain: "${TP_SANDBOX}"
  dnsGlobalTopDomain: "${TP_TOP_LEVEL_DOMAIN}"
  azureSubscriptionDnsResourceGroup: "${TP_DNS_RESOURCE_GROUP}"
  azureSubscriptionId: "${TP_SUBSCRIPTION_ID}"
  azureAwiAsoDnsClientId: "${TP_CLIENT_ID}"
httpIngress:
  enabled: false
  name: main # this is part of cluster issuer name. 
ingress-nginx:
  enabled: false
kong:
  enabled: false
EOF
```


The `dp-config-aks` Helm chart bundles the installation of the ingress controller and storage classes required for the TIBCO Platform. It creates an Azure Application Gateway, storage classes for Azure Disks and Files, and sets up DNS records.

#### Nginx Ingress Controller

This ingress controller can be used for both Data Plane services and user apps.


In order to make sure that the network traffic is allowed from the ingress-system namespace to the Control Plane namespace pods, we need to label this namespace.

```bash
kubectl label namespace ingress-system networking.platform.tibco.com/non-cp-ns=enable --overwrite=true
```

Create a certificate for the ingress controller using the issuer created above
```bash
kubectl apply -f - << EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tp-certificate-main-ingress
  namespace: ingress-system
spec:
  secretName: tp-certificate-main-ingress
  issuerRef:
    name: "cic-cert-subscription-scope-production-main"
    kind: ClusterIssuer
  dnsNames:
    - '*.${TP_DOMAIN}'
EOF
```


```bash
export TP_CLIENT_ID=$(az aks show --resource-group "${TP_RESOURCE_GROUP}" --name "${TP_CLUSTER_NAME}" --query "identityProfile.kubeletidentity.clientId" --output tsv)

helm upgrade --install --wait --timeout 1h --create-namespace \
  -n ingress-system dp-config-aks-nginx dp-config-aks \
  --labels layer=1 \
  --repo "${TP_TIBCO_HELM_CHART_REPO}" --version "^1.0.0" -f - <<EOF
global:
  dnsSandboxSubdomain: "${TP_SANDBOX}"
  dnsGlobalTopDomain: "${TP_TOP_LEVEL_DOMAIN}"
  azureSubscriptionDnsResourceGroup: "${TP_DNS_RESOURCE_GROUP}"
  azureSubscriptionId: "${TP_SUBSCRIPTION_ID}"
  azureAwiAsoDnsClientId: "${TP_CLIENT_ID}"
#dns:
#  domain: "${TP_DOMAIN}"
httpIngress:
  enabled: false
  backend:
    serviceName: dp-config-aks-nginx-ingress-nginx-controller
  ingressClassName: ${TP_MAIN_INGRESS_CLASS_NAME}
  annotations:
    cert-manager.io/cluster-issuer: "cic-cert-subscription-scope-production-main"
    external-dns.alpha.kubernetes.io/hostname: "*.${TP_DOMAIN}"
ingress-nginx:
  enabled: true
  controller:
    service:
      type: LoadBalancer
      annotations:
        external-dns.alpha.kubernetes.io/hostname: "*.${TP_DOMAIN}"
        service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
      enableHttp: false # disable http 80 port on service and NLB
    config:
      use-forwarded-headers: "true"
      proxy-body-size: "150m"
      proxy-buffer-size: 16k
    extraArgs:
      # set the certificate you have created in ingress-system or Control Plane namespace
      default-ssl-certificate: ingress-system/tp-certificate-main-ingress
EOF
```


```bash
kubectl get ingressclass
```

**Expected Output:** The output should now show `azure-application-gateway` and the new `nginx` ingress class.

#### Storage Class

Install the storage classes required for persistent data.

```bash
helm upgrade --install --wait --timeout 1h --create-namespace \
  -n storage-system dp-config-aks-storage dp-config-aks \
  --repo "${TP_TIBCO_HELM_CHART_REPO}" \
  --labels layer=1 \
  --version "^1.0.0" -f - <<EOF
httpIngress:
  enabled: false
clusterIssuer:
  create: false
storageClass:
  azuredisk:
    enabled: ${TP_DISK_ENABLED}
    name: ${TP_DISK_STORAGE_CLASS}
    volumeBindingMode: Immediate
    reclaimPolicy: "Delete"
    parameters:
      skuName: Premium_LRS # other values: Premium_ZRS, StandardSSD_LRS (default)
  azurefile:
    enabled: ${TP_FILE_ENABLED}
    name: ${TP_FILE_STORAGE_CLASS}
    volumeBindingMode: Immediate
    reclaimPolicy: "Delete"
    parameters:
      allowBlobPublicAccess: "false"
      networkEndpointType: privateEndpoint
      skuName: Premium_LRS # other values: Premium_ZRS
    mountOptions:
      - mfsymlinks
      - cache=strict
      - nosharesock
ingress-nginx:
  enabled: false
EOF
```

Verify the storage classes:

```bash
kubectl get storageclass
```

**Expected Output:** The output should show the new `azure-disk-sc` and `azure-files-sc` storage classes. These are the recommended storage classes for TIBCO Platform capabilities.

-----


## 7. Install Observability Tools

The TIBCO Platform requires observability tools to monitor logs and metrics.

### 7.1 Install Elastic Stack

This includes ElasticSearch and Kibana.

```bash
# install eck-operator
helm upgrade --install --wait --timeout 1h --labels layer=1 --create-namespace -n elastic-system eck-operator eck-operator --repo "https://helm.elastic.co" --version "2.16.0"

# install dp-config-es
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n elastic-system ${TP_ES_RELEASE_NAME} dp-config-es \
  --labels layer=2 \
  --repo "${TP_TIBCO_HELM_CHART_REPO}" --version "^1.0.0" -f - <<EOF
domain: ${TP_DOMAIN}
es:
  version: "8.17.3"
  ingress:
    ingressClassName: ${TP_INGRESS_CLASS}
    service: ${TP_ES_RELEASE_NAME}-es-http
  storage:
    name: ${TP_DISK_STORAGE_CLASS}
kibana:
  version: "8.17.3"
  ingress:
    ingressClassName: ${TP_INGRESS_CLASS}
    service: ${TP_ES_RELEASE_NAME}-kb-http
apm:
  enabled: true
  version: "8.17.3"
  ingress:
    ingressClassName: ${TP_INGRESS_CLASS}
    service: ${TP_ES_RELEASE_NAME}-apm-http
EOF
```

Get the host URL for Kibana:

```bash
kubectl get ingress -n elastic-system dp-config-es-kibana -oyaml | yq eval '.spec.rules[0].host'
```

Get the password for the `elastic` user:

```bash
kubectl get secret dp-config-es-es-elastic-user -n elastic-system -o jsonpath="{.data.elastic}" | base64 --decode
```

### 7.2 Install Prometheus Stack

This stack includes Prometheus and Grafana for metrics monitoring.

```bash
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  -n prometheus-system kube-prometheus-stack kube-prometheus-stack \
  --labels layer=2 \
  --repo "https://prometheus-community.github.io/helm-charts" --version "48.3.4" -f <(envsubst '${TP_DOMAIN}, ${TP_INGRESS_CLASS}' <<'EOF'
grafana:
  plugins:
    - grafana-piechart-panel
  ingress:
    enabled: true
    ingressClassName: ${TP_INGRESS_CLASS}
    hosts:
    - grafana.${TP_DOMAIN}
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    remoteWriteDashboards: true
    additionalScrapeConfigs:
    - job_name: otel-collector
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - action: keep
        regex: "true"
        source_labels:
        - __meta_kubernetes_pod_label_prometheus_io_scrape
      - action: keep
        regex: "infra"
        source_labels:
        - __meta_kubernetes_pod_label_platform_tibco_com_workload_type
      - action: keepequal
        source_labels: [__meta_kubernetes_pod_container_port_number]
        target_label: __meta_kubernetes_pod_label_prometheus_io_port
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_pod_label_prometheus_io_port
        target_label: __address__
      - source_labels: [__meta_kubernetes_pod_label_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
        replacement: /$1
  ingress:
    enabled: true
    ingressClassName: ${TP_INGRESS_CLASS}
    hosts:
    - prometheus-internal.${TP_DOMAIN}
EOF
)
```

Get the host URL for Grafana:

```bash
kubectl get ingress -n prometheus-system kube-prometheus-stack-grafana -oyaml | yq eval '.spec.rules[0].host'
```

The default username for Grafana is `admin`, and the password is `prom-operator`.

-----


## 8. Information for TIBCO Data Plane Configuration

You will need the following information to configure the TIBCO Platform Data Plane:

  * **BASE\_FQDN:**
    ```bash
    kubectl get ingress -n ingress-system nginx |  awk 'NR==2 { print $3 }'
    ```
  * **VNET\_CIDR:** `10.4.0.0/16` (from VNet address space)
  * **Ingress Class Names:** `nginx` (for TIBCO BusinessWorks™ Container Edition)
  * **Storage Class Names:**
      * `azure-files-sc` (for `artifactmanager` and logs)
      * `azure-disk-sc` (for persistent data)
  * **Elasticsearch Endpoints:**
      * Internal: `https://dp-config-es-es-http.elastic-system.svc.cluster.local:9200`
      * Public: `https://elastic.<BASE_FQDN>`
  * **Prometheus Service Endpoint:**
      * Internal: `http://kube-prometheus-stack-prometheus.prometheus-system.svc.cluster.local:9090`
      * Public: `https://prometheus-internal.<BASE_FQDN>`
  * **Grafana Endpoint:** `https://grafana.<BASE_FQDN>`
  * **Tracing Server Host:** Same as Elasticsearch internal endpoint.

-----


## 9: Deploy TIBCO Platform Data Plane

Login to your SaaS CP and Register a new Data plane. 

**Note:** If you do not have an access to SaaS CP assigned to your customer, work with TIBCO ATS Team or TIBCO Support.
Usually there is an invitation email sent to the manager or account lead. 

Follow the wizard which will generate following helm commands with a unique DP ID. These helm commands can also be generated using TIBCO Platform Control Plane APIs.

Dataplane name: dp1 or aksdp1 or dp1-prod
Dataplane k8s namespace: dp1

### 9.1. Add Helm Repo

```bash
helm repo add tibco-platform-public https://tibcosoftware.github.io/tp-helm-charts
helm repo update tibco-platform-public
```

### 9.2. Create Namespace

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

### 9.3. Configure Namespace

```bash
helm upgrade --install -n dp1 dp-configure-namespace tibco-platform-public/dp-configure-namespace \
    --version x.x.x \
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

### 9.4. Deploy Core Infrastructure

```bash
helm upgrade --install dp-core-infrastructure -n dp1 tibco-platform-public/dp-core-infrastructure \
    --version x.x.x \
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
Run these helm commands from CLI where you have added kubernetes cluster to your kubeconfig and then in the UI press Done.
---

## Step 10: Provision TIBCO BWCE and Flogo Capabilities from the GUI

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
    kubectl -n dp1 get pods
    ```
5. **Deploy apps**
    - Now you can deploy the apps. Follow the documentation of BWCE or Flogo in case you are not aware of how to build your first project and deploy it to TIBCO Platform

> **Note:** The Control Plane GUI automates the Helm chart installation and configuration for these capabilities. No manual CLI steps are required for this process.

--- 


## 11. Cleanup

To delete the cluster and associated resources:
1. Delete the Data Plane from the TIBCO Control Plane UI
2. Navigate to `scripts/aks` and run the cleanup script:

```bash
cd scripts/aks
./clean-up.sh
```

> **Important:** Ensure all resources to be deleted are in a "started/scaled-up" state (e.g., the AKS cluster) before running the cleanup script.
