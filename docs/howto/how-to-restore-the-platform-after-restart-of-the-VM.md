# how to restore the platform after a restart of the VM

If you restart the VM or WSL image, minikube and the platform will go down. Use the following steps to restart Minikube and the platform:

## Step 1: restart minikube
```bash
minikube start
```

## Step 2: Setup port forwarding
To access the Platform Control Plane Admin UI and the MailDev UI portforwarding to the ingress controller is required when running in minikube.
For this the root user needs to be configured with the kube config.

Step 2.1: su to root

```bash
sudo su -
```

Step 2.2: Run the following script:

Replace <userid> with the userID that you used to login. For AWS and Azure this will be 'tibco'. For WSL it may be another user.

```bash
mkdir -p $HOME/.kube
cp /home/<userid>/.kube/config .kube/config
exit
```

Step 8.3: Setup port forwarding using the following command:

```bash
sudo kubectl port-forward -n ingress-system --address 0.0.0.0 service/ingress-nginx-controller 80:http 443:https
```