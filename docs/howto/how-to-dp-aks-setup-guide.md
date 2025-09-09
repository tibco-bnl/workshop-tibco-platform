

# Setting Up and Configuring Azure Kubernetes Service (AKS) for TIBCO Platform Data Plane

Ref: (Main source reference to this doc)[https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/docs/workshop/aks/data-plane]

This document provides a comprehensive guide for setting up and configuring an Azure Kubernetes Service (AKS) cluster to act as a TIBCO Platform Data Plane. It covers prerequisites, cluster creation, and the installation of necessary tools and components.

-----

## 1\. Prerequisites

Before you begin, ensure you have the following ready:

  * **Azure Subscription:** An Azure subscription with either `Owner` or `Contributor` + `User Access Administrator` roles.
  * **Red Hat Account:** Required for a pull secret.
  * **Command-line Tools:** The following tools must be installed. They can be installed via [Homebrew](https://brew.sh/) on macOS/Linux.
      * `az` (Azure CLI)
      * `oc` (OpenShift CLI)
      * `kubectl`
      * `helm`
      * `jq`, `yq`, `envsubst`, `bash`
  * **Docker:** (Optional) Recommended for using a containerized environment to run CLI tools.
  * **TIBCO Platform Helm Charts Repository:** The repository URL is `https://tibcosoftware.github.io/tp-helm-charts`.

## 2\. Clone the `tp-helm-charts` Repository

All necessary charts and scripts are located in the `tp-helm-charts` repository. Clone it by running the following commands:

```bash
git clone https://github.com/TIBCOSoftware/tp-helm-charts.git
cd tp-helm-charts
```

## 3\. Using a Prebuilt Docker Container for CLI Tools (Optional)

To ensure a consistent environment and avoid local installation issues, you can use a prebuilt Docker container with all the required CLI tools.

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

> **Tip:** If you need to access local files from inside the container, mount your working directory with `-v $(pwd):/workspace`.

All subsequent commands in this guide can be run from within this container shell.

## 4\. Export Required Variables

Before running the setup scripts, you must set the following environment variables. The scripts and configurations rely on these values. We use the prefix `TP_` for "TIBCO PLATFORM" variables.

> **Note:** We are using `az` CLI commands to create prerequisites and the cluster. Please review the parameters below to set the variables correctly.

### Azure Specific Variables

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
export KUBECONFIG=`pwd`/${TP_CLUSTER_NAME}.yaml # kubeconfig file path
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
export TP_AUTHORIZED_IP="86.90.167.198" # whitelisted IP for accessing the cluster
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts # location of charts repo url
export TP_DNS_RESOURCE_GROUP="cic-dns" # resource group for DNS record-sets
```

### Domain Specific Variables

```bash
# To use the same domain for services and user apps:
export TP_DOMAIN="dp1.mle.atsnl-emea.azure.dataplanes.pro"

# To use different domains for services and user apps [OPTIONAL]:
# export TP_DOMAIN="services.dp1.mle.atsnl-emea.azure.dataplanes.pro"
# export TP_APPS_DOMAIN="apps.dp1.mle.atsnl-emea.azure.dataplanes.pro"

export TP_SANDBOX="dp1" # hostname of TP_DOMAIN
export TP_TOP_LEVEL_DOMAIN="mle.atsnl-emea.azure.dataplanes.pro" # top level domain
export TP_MAIN_INGRESS_CLASS_NAME="azure-application-gateway" # name of Azure Application Gateway Ingress Controller
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

## 5\. Create the AKS Cluster

Before creating the cluster, you must log in to Azure and set the correct subscription.

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

## 6\. Install Third-Party Tools

Before deploying the TIBCO Platform Data Plane, you need to install essential third-party tools like Cert Manager, External DNS, Ingress Controllers, and Storage Classes.

> **Note:** The `helm` commands in the following sections use the `--labels layer=<number>` flag. This is supported in Helm v3.13 and above and helps identify chart dependencies for easier uninstallation.

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
EOF
```

**Expected Output:** The `external-dns` release should be installed, and the notes will confirm the chart and app versions.

### 6.3 Install Ingress Controller and Storage Class

The `dp-config-aks` Helm chart bundles the installation of the ingress controller and storage classes required for the TIBCO Platform. It creates an Azure Application Gateway, storage classes for Azure Disks and Files, and sets up DNS records.

#### Nginx Ingress Controller

This ingress controller can be used for both Data Plane services and user apps.

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
dns:
  domain: "${TP_DOMAIN}"
httpIngress:
  enabled: true
  name: nginx
  backend:
    serviceName: dp-config-aks-nginx-ingress-nginx-controller
  ingressClassName: ${TP_MAIN_INGRESS_CLASS_NAME}
  annotations:
    cert-manager.io/cluster-issuer: "cic-cert-subscription-scope-production-nginx"
    external-dns.alpha.kubernetes.io/hostname: "*.${TP_DOMAIN}"
ingress-nginx:
  enabled: true
  controller:
    config:
      use-forwarded-headers: "true"
      proxy-body-size: "150m"
      proxy-buffer-size: 16k
EOF
```

After installation, verify the ingress classes:

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
dns:
  domain: "${TP_DOMAIN}"
clusterIssuer:
  create: false
storageClass:
  azuredisk:
    enabled: ${TP_DISK_ENABLED}
    name: ${TP_DISK_STORAGE_CLASS}
  azurefile:
    enabled: ${TP_FILE_ENABLED}
    name: ${TP_FILE_STORAGE_CLASS}
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

## 7\. Install Observability Tools

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

## 8\. Information for TIBCO® Data Plane Configuration

You will need the following information to configure the TIBCO Platform Data Plane.

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

## 9\. Cleanup

To delete the cluster and associated resources, first delete the Data Plane from the TIBCO Control Plane UI. Then, navigate to the `scripts/aks` directory and run the cleanup script.

```bash
cd scripts/aks
./clean-up.sh
```

> **Important:** Ensure all resources to be deleted are in a "started/scaled-up" state (e.g., the AKS cluster) before running the cleanup script.
