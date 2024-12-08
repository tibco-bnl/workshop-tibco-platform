# Install TIBCO Platform Data Plane on Docker Desktop for WSL

This document contains a description on how to install the TIBCO Platform Data Plane on WSL. 
The [TIBCO Platform](https://docs.tibco.com/products/tibco-control-plane-1-3-0) offers the option to create a so-called Cloud Based Data Plane. This is a Kubernetes based environment that is used to run TIBCO applications like BWCE, Flogo, EMS, etc. 
In order to use a data plane, one has to register it at a Control Plane. This can be a self-hosted Control Plane or a TIBCO hosted Control Plane.
A Data Plane running on Docker Desktop for WSL should only be used for educational or demonstration purposes. 


# Prerequisites
In order to setup the Data Plane the following prerequisites must be met:
1) Have Docker Desktop for Windows Subsystem for Linux (WSL) installed. See [here](https://docs.docker.com/desktop/setup/install/windows-install/). Please mind: use an installation on WSL, NOT on Hyper-V.
2) Enable Kubernetes on Docker Desktop.
a) ![Click settings --> Kubernetes](DockerDesktop1.png)
b) ![Set 'enable Kubernetes' en click 'Apply & Restart'](DockerDesktop2.png)
Wait for Kubernetes to start.
c) Open a command prompt and type 'kubectl get namespaces'. 


# Installation
Use the following steps to install a fresh Data Plane on Docker Desktop for WSL. The process takes about 20 minutes. It will install a standalone Data Plane including all observability tooling and an Ingress controller.
1) Open a Command Prompt.
2) Make a new directory (mkdir platforminstall) and go to this directory (cd platforminstall)
![platform install directory](platforminstall.png)
3) Type 'wsl' to get a wsl prompt.
4) Run the installation script: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tibco-bnl/workshop-tibco-platform/main/tibcodpforddforwsl/bin/InstallTibcoDataPlaneOnDDForWSL.sh)

# Register the Data Plane


