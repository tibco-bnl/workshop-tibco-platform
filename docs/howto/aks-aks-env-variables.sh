#!/bin/bash
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv) # subscription id
export TP_TENANT_ID=$(az account show --query tenantId -o tsv) # tenant id
export TP_AZURE_REGION="westeurope" # region of resource group
export TP_RESOURCE_GROUP="kul-atsbnl" # set the resource group name in which all resources will be deployed
export TP_CLUSTER_NAME="dp1-aks-aauk-kul" # name of the cluster to be provisioned
export TP_KUBERNETES_VERSION="1.32.6" # refer to: https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions?tabs=azure-cli
export TP_USER_ASSIGNED_IDENTITY_NAME="${TP_CLUSTER_NAME}-identity" # user assigned identity to be associated with the cluster

#Uncomment if you are running from docker image but nevertheless this is optional
#export KUBECONFIG=`pwd`/${TP_CLUSTER_NAME}.yaml # kubeconfig file path

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
export TP_NETWORK_POLICY="azure" # possible values: "azure", "calico", "none"
export TP_NETWORK_PLUGIN="azure" # possible values: "azure", "calico", "none"
export TP_AUTHORIZED_IP="" # whitelisted IP for accessing the cluster
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts # location of charts repo url
export TP_DNS_RESOURCE_GROUP="kul-atsbnl" # resource group for DNS record-sets
export TP_DOMAIN="dp1.kul.atsnl-emea.azure.dataplanes.pro"
export TP_SANDBOX="dp1" # hostname of TP_DOMAIN
export TP_TOP_LEVEL_DOMAIN="kul.atsnl-emea.azure.dataplanes.pro" # top level domain
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
