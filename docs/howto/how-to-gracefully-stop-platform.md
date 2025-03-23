# how to gracefully stop platform

You can gracefully stop TIBCO platform as follows:

## Step 1: Login to Ubuntu
1. [For AWS or Azure](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
2. [For WSL](docs/baseplatforms/login-to-an-ubuntu-wsl.md).



## Step 2: stop minikube
```bash
minikube stop
```

## Step 3: exit from Ubuntu and bring down the Ubuntu server


Step 3.1: Exit
Run the following command one or more times to exit from the server.
```bash
exit
```

Step 3.2: Bring down the server.

Bring down the server. For Azure and AWS do so from the Azure/AWS console.
For WSL run the following command to get a list of images:

```cmd
wsl -l -v
```

Bring down the image used to run TIBCO Platform

```cmd
wsl -l -v
wsl --terminate <DistroName>
```