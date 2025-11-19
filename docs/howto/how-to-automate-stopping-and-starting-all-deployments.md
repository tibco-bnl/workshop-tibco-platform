# How to automate stopping and starting all deployments in a K8S cluster

## Rationale
On some cloud platforms the costs of a K8S cluster is depending on the deployed pods. For instance on AWS, EKS based on Fargate nodes each running pod add costs.
Since AWS does not have a K8S cluster stop function the nodes need to be stopped.
This how to document provides some scripts to automate this.

## Features
The scripting to automate this is bash (linux/mac) based and required kubectl access to the target cluster.
There are three scripts to accomplish the following features:
1) Store information regarding all the deployements and the number of running pods (scale). This information will be stored in a file.
2) Scale down all the deployements for all namespaces
3) Scale up all the deployements for all namespaces based on the stored information

## Scripts

### scale-01-deploment-capture.sh

``` bash
#!/bin/bash

echo "Saving current replica counts..."

kubectl get deploy --all-namespaces -o json \
  | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.spec.replicas)"' \
  > replicas_backup.txt

echo "Saved to replicas_backup.txt"
```
### scale-02-deployment-down.sh

``` bash
#!/bin/bash

echo "Scaling down all deployments in all namespaces to 0..."

DEPLOYS=$(kubectl get deploy --all-namespaces -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"')

while read -r namespace name; do
    echo "Scaling deployment $name in namespace $namespace"
    kubectl scale deployment "$name" -n "$namespace" --replicas=0
done <<< "$DEPLOYS"

echo "Done."
```

## scale-03-deployement-restore.sh

``` bash
#!/bin/bash

echo "Restoring replica counts..."

while read -r namespace name replicas; do
    echo "Scaling $namespace/$name to $replicas"
    kubectl scale deployment "$name" -n "$namespace" --replicas="$replicas"
done < replicas_backup.txt

echo "Done."
```


