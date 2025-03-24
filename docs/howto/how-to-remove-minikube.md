# how to remove minikube

If for any reason you want to remove minikube run the following command

## Step 1: Remove minikube

```bash
minikube delete
```

## Step 2: Remove minikube directories

After step 1 finished!!
```bash
rm -r ~/.minikube
rm -r ~/.kube
```
