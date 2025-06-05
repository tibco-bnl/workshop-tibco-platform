#!/bin/bash

# -----------------------------------------------------------------------------
# Azure Red Hat OpenShift (ARO) Environment Variables Initialization
# -----------------------------------------------------------------------------
az login

# Azure Subscription and Tenant
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TP_TENANT_ID=$(az account show --query tenantId -o tsv)

# Azure Region and Resource Group
export TP_AZURE_REGION="westeurope"                # Change if needed
export TP_RESOURCE_GROUP="kul-atsbnl-flogo-azfunc" # Change if needed

# Cluster Configuration
export TP_CLUSTER_NAME="aroCluster"
export TP_WORKER_COUNT=6

# Network Configuration
export TP_VNET_NAME="openshiftvnet"
export TP_MASTER_SUBNET_NAME="masterOpenshiftSubnet"
export TP_WORKER_SUBNET_NAME="workerOpenshiftSubnet"
export TP_VNET_CIDR="10.0.0.0/8"
export TP_MASTER_SUBNET_CIDR="10.17.0.0/23"
export TP_WORKER_SUBNET_CIDR="10.17.2.0/23"

# Worker Node Configuration
export TP_WORKER_VM_SIZE="Standard_D8s_v5"
export TP_WORKER_VM_DISK_SIZE_GB="128"

# TIBCO Platform Helm Chart Repo
export TP_TIBCO_HELM_CHART_REPO="https://tibcosoftware.github.io/tp-helm-charts"

# Print all TP_* variables for verification
echo "Initialized the following TP_* environment variables:"
env | grep ^TP_



az aro list-credentials --name ${TP_CLUSTER_NAME} --resource-group ${TP_RESOURCE_GROUP}
apiServer=$(az aro show -g ${TP_RESOURCE_GROUP} -n ${TP_CLUSTER_NAME} --query apiserverProfile.url -o tsv)
oc login ${apiServer} -u kubeadmin -p <kubeadminPassword>
