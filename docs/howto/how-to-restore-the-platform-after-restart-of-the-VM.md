# how to restore the platform after a restart of the VM

If you restart the VM or WSL image, minikube and the platform will go down. Use the following steps to restart Minikube and the platform:

## Step 1: restart minikube

Step 1.1: Login to Ubuntu
1. [For AWS or Azure](docs/baseplatforms/login-to-an-ubuntu-aws-or-azure-instance.md).
2. [For WSL](docs/baseplatforms/login-to-an-ubuntu-wsl.md).


Step 1.1: Check to make sure you are not logged in as root.

Make sure you are not logged in with root. Run the following command to check:

```bash
whoami
```

If you are logged in with root than run the following command to switch the user to 'tibco' (or choose the user you used to install minikube on WSL).
```bash
su tibco
```



## Step 2: restart minikube
```bash
minikube start
```

## Step 3: Setup port forwarding
To access the Platform Control Plane Admin UI and the MailDev UI portforwarding to the ingress controller is required when running in minikube.
For this the root user needs to be configured with the kube config.

Step 3.1: su to root

```bash
sudo su -
```

Step 3.2: Run the following script:

Replace <userid> with the userID that you used to login. For AWS and Azure this will be 'tibco'. For WSL it may be another user.

```bash
mkdir -p $HOME/.kube
cp /home/tibco/.kube/config .kube/config
exit
```

Warning: if you use WSL and you used another user than 'tibco' to install minikube, replace 'tibco' with that userid.

Step 3.3: Setup port forwarding using the following command:

```bash
sudo kubectl port-forward -n ingress-system --address 0.0.0.0 service/ingress-nginx-controller 80:http 443:https
```

Step 3.4: Release the prompt

Type <contr>Z

Run the following command to move the port-forward to the background:
```bash
bg
```