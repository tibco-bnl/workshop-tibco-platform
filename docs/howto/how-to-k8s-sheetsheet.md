# K8S sheetsheet
This document contains all kind of usefull commands for k8s platform

## Debug distroless containers
Distroless containers do not allow shell sessions (kubectl exec ...).
In order to debug such containers the kubectl debug command can be used.
Especially the container image nicolaka/netshoot is usefull for all kind of troubleshooting (https://github.com/nicolaka/netshoot)

kubectl debug -it <POD_TO_DEBUG> --image=nicolaka/netshoot --target=<CONTAINER_TO_DEBUG> --share-processes


## Delete namespaces stuck in status Terminating

``` bash
kubectl get namespace "stucked-namespace" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -
```

Replace "stucked-namespace" with the actual name of the namespace. Please not this is occuring twice (2) in the above command.
