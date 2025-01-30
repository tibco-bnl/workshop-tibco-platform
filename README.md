

# workshop-tibco-platform

This project is designed to provide a comprehensive workshop on the TIBCO platform. It includes various modules and exercises to help users understand and utilize the TIBCO platform effectively.

| Name | Date |   Version   | Remarks                                                   |
|:---------------------|----------|:-----------:|:--------------------------------------------------------------|
| Kulbhushan               | 26/11/2024 | v1  | Initial draft |
| Jurriaan               | 21/1/2025 | v2  | Rebased and Merged tp_on_minikube and doc branches also cleaned up unwanted documentation |
| Marco               | 28/1/2025 | v3  | Separated port forwading into a separate script |
| Kulbhushan               | 29/1/2025 | v4  | Added script to generate self ca signed certificates and tokens |

# TIBCO Platform Workshop

This repository contains a TIBCO Platform Workshop. The material is intended for TIBCO customers and partners who want to create a TIBCO Platform 'sandbox environment'. The aim of this sandbox is to get to learn the platform. A sandbox is intended or supported for production purposes. 

The following sandbox environments can be created:

1) TIBCO Platform on Docker Desktop for WSL. This setup is suitable for users with Windows 11 and Windows Subsystem for Linux (WSL) + Docker Desktop. In this setup the Kubernetes environment of Docker Desktop is used as the base infrastructure.

[See for a description here](install-cp-and-dp-on-dockerdesktop-on-wsl/readme.md).


2) TIBCO Platform on Minikube Ubuntu on WSL. This setup is suitable for users with Windows 11 and Windows Subsystem for Linux (WSL). The platform is installed on an instance of Minikube on Ubuntu running in WSL.
[See for a description here](install-cp-and-dp-on-minikube-on-WSL/readme.md).


3) TIBCO Plaform on TIBCO Platform on Minikube Ubuntu on AWS. This setup is suitable for departments that want a departemental sandbox. The sandbox is installed on an instance of Minikube on Ubuntu running in AWS.
[See for a description here](install-cp-and-dp-on-minikube-on-AWS/readme.md).
