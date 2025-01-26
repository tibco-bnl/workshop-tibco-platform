

This repository contains a TIBCO Platform Workshop. The material is intended for TIBCO customers and partners who want to create a TIBCO Platform 'sandbox environment'. The aim of this sandbox is to get to learn the platform. A sandbox is intended or supported for production purposes.

In order to setup the platform, four steps are required:

| Name | Date |   Version   | Remarks                                                   |
|:---------------------|----------|:-----------:|:--------------------------------------------------------------|
| Kulbhushan               | 26/11/2024 | v1  | Initial draft |
| Jurriaan               | 21/1/2025 | v2  | Rebased and Merged tp_on_minikube and doc branches also cleaned up unwanted documentation |
| Marco               | 28/1/2025 | v3  | Separated port forwading into a separate script |
| Kulbhushan               | 29/1/2025 | v4  | Added script to generate self ca signed certificates and tokens |

(A) Setup a base VM
(B) Prepare deployment and deploy kubernetes
(C) Deploy the platform
(D) Configure the platform

## (A) Setup the base VM

The following sandbox VMs can be used:

1) Docker Desktop for WSL. This setup is suitable for users with Windows 11 and Windows Subsystem for Linux (WSL) + Docker Desktop. In this setup the Kubernetes environment of Docker Desktop is used as the base infrastructure.

[See for a description here](docs/baseplatforms/install-dockerdesktop-on-wsl.md).


2) Ubuntu on WSL. This setup is suitable for users with Windows 11 and Windows Subsystem for Linux (WSL). The platform is installed on an instance of Ubuntu running in WSL.
[See for a description here](docs/baseplatforms/install-ubuntu-on-wsl.md).


3) Ubuntu on AWS. This setup is suitable for departments that want a departemental sandbox. The sandbox is installed on an a shared instance of Ubuntu running on AWS.
[See for a description here](docs/baseplatforms/install-ubuntu-on-aws.md).

4) Ubuntu on Azure. This setup is suitable for departments that want a departemental sandbox. The sandbox is installed on an a shared instance of Ubuntu running on Azure.
[See for a description here](docs/baseplatforms/install-ubuntu-on-azure.md).


## (B) Prepare deployment and deploy kubernetes

To run the TIBCO platform, a Kubernetes platform is required. Next to that some tools need to be installed. The following flavours of Kubernetes are installed:

1) Minikube. Minikube can be used when using the following base platforms:
a) Ubuntu on WSL. To install tooling and minikube, use the following two steps:
    i) [Login to the Ubuntu image on WSL](docs/baseplatforms/login-to-ubuntu-wsl.md).
    ii) [Prepare the platform deployment with minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md).
b) Ubuntu on AWS. To install tooling and minikube, use the following two steps:
    i) [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
    ii) [Prepare the platform deployment with minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md).
c) Ubuntu on Azure. To install tooling and minikube, use the following two steps:
    i) [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
    ii) [Prepare the platform deployment with minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md).

2) Docker Desktop Kubernetes. When using Docker Desktop for WSL, the included Kubernetes environment can be used. Nevertheless a side-car Ubuntu image need to be setup to install the TIBCO platform. 

## (C) Deploy the platform
Once a Kubernetes platform (controlplain and dataplain) is installed the TIBCO platform can be installed. For that the following procedures apply:

a) Ubuntu on WSL. To install the TIBCO Platform use the following steps:
    i) [Login to the Ubuntu image on WSL](docs/configure-platform/login-to-ubuntu-wsl.md).
    ii) [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md).
b) Docker Desktop Kubernetes. To install the TIBCO Platform use the following steps:
    i) [Login to the Ubuntu image on WSL](docs/xxxxxx.md).
    ii) [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md)

b) Ubuntu on AWS.  To install the TIBCO Platform use the following steps::
    i) [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
    ii) [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md).
c) Ubuntu on Azure. To install the TIBCO Platform use the following steps:
    i) [Login to an Ubuntu AWS or Azure instance](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
    ii) [Install the TIBCO Platform](docs/configure-platform/install-tibco-platform.md).
