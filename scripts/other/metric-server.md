```markdown
# Installing Metrics Server on Minikube using Helm

To install the Metrics Server on Minikube using Helm, you can use the following command:

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server \
    --namespace kube-system \
    --create-namespace \
    --set serviceAccount.name=metrics-server \
    --set serviceAccount.create=true \
    --set "args[0]=--kubelet-insecure-tls" \
    --set "args[1]=--metric-resolution=90s"
```

This command aligns with the ArgoCD application configuration provided.
```