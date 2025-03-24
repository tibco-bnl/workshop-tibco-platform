# how to update a platform

TIBCO provide regular updates of the platform. This document contains the procedure to update the platform when running the control plane and data plane on a single Ubuntu image with minikube.

## Step 1: Login to the Ubuntu server
1. [For AWS or Azure](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
2. [For WSL](docs/baseplatforms/login-to-an-ubuntu-wsl.md).

## Step 2: Get the right helm repository

```bash
helm repo add tibco-platform https://tibcosoftware.github.io/tp-helm-charts
```

## Step 3: Update the control plane bootstrap 

Step 3.1: Run the following command.

```bash
helm upgrade --install --reset-then-reuse-values -n cp1-ns platform-bootstrap tibco-platform-public/platform-bootstrap --version=<version>
```

Check the version [here](https://docs.tibco.com/pub/platform-cp/1.5.0/doc/html/Default.htm#Installation/helm-chart-version-matrix.htm). Use the version listed under 'platform-bootstrap'.


Step 3.2: Check progress, run the following command:
```bash
kubectl get pods -n cp1-ns
```

Make sure all pods are either in 'running' status or 'completed' status.

Step 3.3: Check the status of the help chart
```bash
helm status platform-bootstrap -n cp1-ns
```
Make sure the status of the chart is 'deployed'. It should look something like:

```bash
helm status platform-bootstrap -n cp1-ns
NAME: platform-bootstrap
LAST DEPLOYED: Mon Mar  3 12:06:09 2025
NAMESPACE: cp1-ns
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
Tibco Platform Control Plane Bootstrap
```

## Step 4: Update the control plane platform-base

Step 4.1: Run the following command.

```bash
helm upgrade --install --reset-then-reuse-values -n cp1-ns platform-base tibco-platform/platform-base --version=<version>
```

Check the version [here](https://docs.tibco.com/pub/platform-cp/1.5.0/doc/html/Default.htm#Installation/helm-chart-version-matrix.htm). Use the version listed under 'platform-base'.

Please mind: It may take up to an hour for the update to complete.



Step 3.2: Check progress, run the following command:
```bash
kubectl get pods -n cp1-ns
```

Make sure all pods are either in 'running' status or 'completed' status.

Step 3.3: Check the status of the help chart
```bash
helm status platform-base -n cp1-ns
```
Make sure the status of the chart is 'deployed'. 

