#!/bin/bash

# -----------------------------------------------------------------------------
# Azure Red Hat OpenShift (ARO) Environment Variables and Setup
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Azure Specific Variables
# -----------------------------------------------------------------------------
export TP_SUBSCRIPTION_ID=$(az account show --query id -o tsv)           # Subscription ID
export TP_TENANT_ID=$(az account show --query tenantId -o tsv)           # Tenant ID
export TP_AZURE_REGION="westeurope"                                      # Azure Region
export TP_RESOURCE_GROUP="kul-atsbnl-flogo-azfunc"                       # Resource Group

# -----------------------------------------------------------------------------
# Cluster Configuration Variables
# -----------------------------------------------------------------------------
export TP_CLUSTER_NAME="aroCluster"
export TP_WORKER_COUNT=6

# -----------------------------------------------------------------------------
# Network Configuration Variables
# -----------------------------------------------------------------------------
export TP_VNET_NAME="openshiftvnet"
export TP_MASTER_SUBNET_NAME="masterOpenshiftSubnet"
export TP_WORKER_SUBNET_NAME="workerOpenshiftSubnet"
export TP_VNET_CIDR="10.0.0.0/8"
export TP_MASTER_SUBNET_CIDR="10.17.0.0/23"
export TP_WORKER_SUBNET_CIDR="10.17.2.0/23"

# -----------------------------------------------------------------------------
# Worker Node Configuration
# -----------------------------------------------------------------------------
export TP_WORKER_VM_SIZE="Standard_D8s_v5"
export TP_WORKER_VM_DISK_SIZE_GB="128"

# -----------------------------------------------------------------------------
# Tooling Variables
# -----------------------------------------------------------------------------
export TP_TIBCO_HELM_CHART_REPO="https://tibcosoftware.github.io/tp-helm-charts"

