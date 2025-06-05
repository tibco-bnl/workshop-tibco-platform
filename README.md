# TIBCO Platform Workshop

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

Below is a list of documentation files in this repository for quick reference:

- [Install TIBCO Platform on Minikube or Docker Desktop kubernetes](/scripts/running_platform_installer.md)
- [How to Set Up EKS Fargate EFS and Deploy TIBCO Data Plane](docs/howto/how-to-dp-eks-fargate-efs-setup-guide.md)
- [How to Set Up Azure Red Hat OpenShift (ARO) Cluster and Deploy TIBCO Platform Data Plane](docs/howto/how-to-dp-openshift-aro-aks-setup-guide.md)
- [How to Set Up Observability on a DP running on Azure Red Hat OpenShift (ARO) Cluster](docs/howto/how-to-dp-openshift-observability.md)



---

## Doc Control

| Name        | Date       | Version | Remarks                                                                                  |
|:------------|:-----------|:-------:|:-----------------------------------------------------------------------------------------|
| Kulbhushan  | 26/11/2024 | v1      | Initial draft                                                                            |
| Jurriaan    | 21/1/2025  | v2      | Rebased and merged tp_on_minikube and doc branches; cleaned up unwanted documentation     |
| Marco       | 28/1/2025  | v3      | Separated port forwarding into a separate script                                          |
| Kulbhushan  | 29/1/2025  | v4      | Added script to generate self-signed CA certificates and tokens                           |
| Kulbhushan  | 03/06/2025 | v5      | Added ARO setup guide for 1.7 version                                                    |
| Marco  | 03/06/2025 | v5      | Added How to Set Up EKS Fargate EFS and Deploy TIBCO Data Plane for 1.7 version                                                    |
| Kulbhushan  | 05/06/2025 | v5      | Added ARO Observability config - only logs working  
