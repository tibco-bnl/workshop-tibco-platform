# how to create resources

Every Data Plane has so-called resources:
- Storage
- Ingress Controllers
- Databases

If you want to use any of these (which is for example required when adding a capability), you first have to add the resources. This document contains instructions on creating Storage and Ingress Controllers.

## Step 1: Adding storage
Applications require storage. Within minikube one type of storage is available (standard). Before creating capabilities, a storage resource must be added using the following steps:

Step 1.1: Open your dataplane

Step 1.1a: Open your DataPlane
![Open you DataPlane](../images/open-dp.png)

Step 1.1b: Select 'go to dataplane'
![Select 'go to dataplane'](../images/open-dp2.png)

Step 1.1c: Select 'Dataplane configuration'
![Select 'Dataplane configuration'](../images/select-dp-configuration.png)


Step 1.2: Add storage class

Step 1.2a: Click 'Add storage class'
![Select 'Dataplane configuration'](../images/click-add-storage-class.png)

Step 1.2b: Create a storage class with the following values:
Resource Name: standard
Description: Storage Class Provided by MiniKube
Storage Class Name: standard

![Select 'Dataplane configuration'](../images/add-storage-class.png)

## Step 2: Create an Ingress Controller
For every capability one Ingress controller needs to be created. 

Step 2.1: Repeat step 1.1.

Step 2.2: Add ingress controller

Step 2.2a: Click 'Click 'Add Ingress Controler'
![Select 'Add Ingress Controler'](../images/click-add-ingress-controller.png)

Step 2.2b: Click 'Click 'Add Ingress Controler'
![Select 'Configure the ingress controller'](../images/ingress-controller.png)
Ingress Controller: nginx
Ingress Class Name: nginx
Resourcename: nginx-{capability}. For example: nginx-flogo
FQDN: {capability}.localhost.dataplane.pro. For example: flogo.localhost.datapane.pro

