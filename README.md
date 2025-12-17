# TIBCO Platform Workshop

#### [GH Pages Web link](https://tibco-bnl.github.io/workshop-tibco-platform/)
#### [Github source code link](https://github.com/tibco-bnl/workshop-tibco-platform)

This repository contains material for the TIBCO Platform Workshop. The material is intended for TIBCO customers and partners who want to create a TIBCO Platform sandbox environment and experiment with it. The aim of this sandbox is to help users learn the platform. **A sandbox is NOT intended or supported for production purposes.**

## Table of Contents: In order to setup the platform, four steps are required:

1. [(A) Setup the Base VM](#a-setup-the-base-vm)
2. [(B) Prepare Deployment and Deploy Kubernetes](#b-prepare-deployment-and-deploy-kubernetes)
3. [(C) Install the Platform](#c-install-the-platform)
4. [(D) Configure the Platform](#d-configure-the-platform)

## Other documentation in this repo: 
5. [Documentation Index](#documentation-index)
6. [Doc Control](#doc-control)

---

## (A) Setup the Base VM

The following sandbox VMs can be used:

1. **Docker Desktop for WSL with Kubernetes**  
    Suitable for users with Windows 11 and Windows Subsystem for Linux (WSL) + Docker Desktop including Kubernetes. In this setup, the Kubernetes environment of Docker Desktop is used as the base infrastructure.  
    [See description here](docs/baseplatforms/install-docker-desktop-on-wsl.md)

2. **Ubuntu on WSL**  
    Suitable for users with Windows 11 and WSL. The platform is installed on an instance of Ubuntu running in WSL.  
    [See description here](docs/baseplatforms/install-ubuntu-on-wsl.md)

3. **Ubuntu on AWS**  
    Suitable for departments that want a departmental sandbox. The sandbox is installed on a shared instance of Ubuntu running on AWS.  
    [See description here](docs/baseplatforms/install-ubuntu-on-aws.md)

4. **Ubuntu on Azure**  
    Suitable for departments that want a departmental sandbox. The sandbox is installed on a shared instance of Ubuntu running on Azure.  
    [See description here](docs/baseplatforms/install-ubuntu-on-azure.md)

---

## (B) Prepare Deployment and Deploy Kubernetes

To run the TIBCO platform, a Kubernetes platform is required. Some tools also need to be installed. The following Kubernetes flavors are supported:

1. **Docker Desktop for WSL with Kubernetes**  
    *Work in progress.*

2. **Minikube**  
    Minikube can be used with the following base platforms:

    - **Ubuntu on WSL**  
      1. [Login to the Ubuntu image on WSL](docs/baseplatforms/login-to-ubuntu-wsl.md)
      2. [Prepare the platform deployment with Minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md)

    - **Ubuntu on AWS**  
      1. [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md)
      2. [Prepare the platform deployment with Minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md)

    - **Ubuntu on Azure**  
      1. [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md)
      2. [Prepare the platform deployment with Minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md)

---

## (C) Install the Platform

Once a Kubernetes platform (Control Plane and Data Plane) is installed, the TIBCO platform can be installed. Use the following procedures:

1. **Docker Desktop Kubernetes**  
    *Work in progress.*  
    1. [Login to the Ubuntu image on WSL](docs/xxxxxx.md)  
    2. [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md)

2. **Ubuntu with Minikube on WSL**  
    1. [Login to the Ubuntu image on WSL](docs/baseplatforms/login-to-ubuntu-wsl.md)
    2. [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md)

3. **Ubuntu with Minikube on AWS**  
    1. [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md)
    2. [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md)

4. **Ubuntu with Minikube on Azure**  
    1. [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md)
    2. [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md)

---

## (D) Configure the Platform

Once the TIBCO platform is installed, a number of configurations are required.

Use [this guide](docs/configure-platform/configure-tibco-platform.md) to perform the basic configuration of the platform.

---

## Documentation Index


### Control Plane
- [How to: Control Plane setup AKS environment variables](docs/howto/aks-aks-env-variables.sh)
- [How to: Setup AWS EKS storage for Control Tower](docs/howto/how-to-controltower-aws-eks-storage-only.md)

### Data Planes / Control Tower
- [How to: Setup Control Tower on AWS EKS](docs/howto/how-to-controltower-aws-eks.md)
- [How to: Setup Control Tower on Azure AKS](docs/howto/how-to-controltower-azure-aks.md)
- [How to: Set up AKS Cluster and Deploy TIBCO Platform Data Plane](docs/howto/how-to-dp-aks-setup-guide.md)
- [How to: Set Up EKS Fargate EFS and Deploy TIBCO Data Plane](docs/howto/how-to-dp-eks-fargate-efs-setup-guide.md)
- [How to: Add a capability](docs/howto/how-to-add-a-capability.md)
- [How to: Create resources](docs/howto/how-to-create-resources.md)
- [How to: Set Up Observability on a DP running on Azure Red Hat OpenShift (ARO) Cluster](docs/howto/how-to-dp-openshift-observability.md)
- [How to: Set Up Azure Red Hat OpenShift (ARO) Cluster and Deploy TIBCO Platform Data Plane](docs/howto/how-to-dp-openshift-aro-aks-setup-guide.md)
- [How to: Setup controltower on minikube](docs/howto/how-to-setup-controltower-on-minikube.md)

### Applications
- [How to: Run BW processes as a cronjob](docs/howto/hot-to-run-bw-process-as-cronjob.md)
- [How to: Expose EMS outside cluster](docs/howto/how-to-ems-expose-outside-cluster.md)
- [How to: Mount jks in bwce app](docs/howto/how-to-mount-jks-in-bwce-app.md)
- [How to: Mount a license file as secret](docs/howto/how-to-mount-license-file-as-secret.md)

### Infra (general)
- [How to: Automate scaling up and down deployments](docs/howto/how-to-automate-stopping-and-starting-all-deployments.md)
- [How to: Gracefully stop the platform](docs/howto/how-to-gracefully-stop-platform.md)
- [How to: Install separate platform components](docs/howto/how-to-install-seperate-platform-components.md)
- [How to: K8S sheetsheet](docs/howto/how-to-k8s-sheetsheet.md)
- [How to: Remove minikube](docs/howto/how-to-remove-minikube.md)
- [How to: Restore the platform after restart of VM](docs/howto/how-to-restore-the-platform-after-restart-of-the-VM.md)
- [How to: Run the platform provisioner again](docs/howto/how-to-run-the-platform-provisioner-again.md)
- [How to: Upgrade a platform](docs/howto/how-to-update-a-platform.md)

### Security
- [IP Whitelist Configuration for Ingress Endpoints](scripts/other/dp4/README.md) - Manage IP-based access control for UI ingress endpoints

---

## Doc Control

| Name        | Date       | Version | Remarks                                                                                  |
|:------------|:-----------|:-------:|:-----------------------------------------------------------------------------------------|
| Kulbhushan  | 26/11/2024 | v1      | Initial draft                                                                            |
| Jurriaan    | 21/1/2025  | v2      | Rebased and merged tp_on_minikube and doc branches; cleaned up unwanted documentation     |
| Marco       | 28/1/2025  | v3      | Separated port forwarding into a separate script                                          |
| Kulbhushan  | 29/1/2025  | v4      | Added script to generate self-signed CA certificates and tokens                           |
| Kulbhushan  | 03/06/2025 | v5      | Added ARO setup guide for 1.7 version                                                    |
| Marco  | 03/06/2025 | v5      | Added How to Set Up EKS Fargate EFS and Deploy TIBCO Data Plane for 1.7 version          |                                          |
| Kulbhushan  | 05/06/2025 | v5      | Added ARO Observability config - only logs working  |
| Kulbhushan  | 12/09/2025 | v6      | Added AKS DP setup document |
| Marco       | 19/11/2025 | v7      | Refreshed Document section |
