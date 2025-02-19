# Provision Developer Hub


## Requirements
To provision developer hub the following aspects are required:

* Active dataplane on a controlplane
* User with sufficient right on the dataplane to deploy capabilities
* command line access to update the core DNS configuration

## Provisioning

The provisioning of the developer hub involves the following steps:

1) update Core DNS with the developer hub dns entry
2) Provision Developer hub capability in dataplane via ui


## Step 1: update Core DNS with the developer hub dns entry

Retrieve the IP-address of the minikube node

```
minikube node list
```
![alt text](images/image-1.png)


Open coreDNS configuration for editting

```
kubectl -n kube-system edit configmaps coredns
```

![alt text](images/image_dns1.png)

Addin the host section the IP-Address found above with the dns name of the developerhub:

(example)
```
192.168.49.2 devhub.benelux.cp1-my.localhost.dataplanes.pro
```

![alt text](images/image_dns2.png)


save and exit the configmap
```
[esc]:q
```

## Step2: Provision Developer hub capability in dataplane via ui


Open the Control plan UI and access the dataplane

![alt text](images/image_dp.png)

Click Provision a capability

Start Provision TIBCO Developer Hub

Add storage. Storage class name need to be in line with the k8s platform (minikube=standard)

![alt text](images/addStorage.png)

Add ingress Controller.

![alt text](images/addIngress.png)


![alt text](images/addResources.png)


![alt text](images/configuration.png)


Don't provide customer configuration and confirm.


![alt text](images/wait.png)

