# Install microk8s on WSL2 Ubuntu on Windows

In order to run the TIBCO Platform Micro8s is to be installed on the created Ubuntu image on WSL. Follow these steps to install microk8s on WSL2 Ubuntu on Windows:


## Step 1: start the Ununtu image

Step 1.1: If you haven't done so already open a command prompt and go to the directory earlier created for the TIBCO platform
```windows terminal
mkdir c:\tibcoplatform
```

Step 1.2: Open wsl on the tibcoplatform image
Run the following command:
```windows terminal
wsl -d tibcoplatform
```

You will be transferred to a terminal that runs on the Ubuntu WSL image earlier created. All commands from this moment in time are carried out on this Linux terminal.


## Step 2: Install micro8s 

Step 2.1: update and upgrade packeges
    ```bash
    sudo apt update
    sudo apt upgrade -y
    ```

Step 2.2: Install micro8s
    ```bash
    sudo snap install microk8s --classic
    ```

Step 2.3: Add Current User to microk8s Group 
    ```bash
    sudo usermod -a -G microk8s $USER
    sudo chown -f -R $USER ~/.kube
    ```

Step 2.4: Apply Group Changes 
    ```bash
    newgrp microk8s
    ```

Step 2.5: Verify Installation 
    ```bash
    sudo microk8s status --wait-ready
    ```
The output must be something like this:

microk8s is running
high-availability: no
  datastore master nodes: 127.0.0.1:19001
  datastore standby nodes: none
addons:
  enabled:
    dns                  # (core) CoreDNS
    ha-cluster           # (core) Configure high availability on the current node
    helm                 # (core) Helm - the package manager for Kubernetes
    helm3                # (core) Helm 3 - the package manager for Kubernetes
  disabled:
    cert-manager         # (core) Cloud native certificate management
    cis-hardening        # (core) Apply CIS K8s hardening
    community            # (core) The community addons repository
    dashboard            # (core) The Kubernetes dashboard
    gpu                  # (core) Alias to nvidia add-on
    host-access          # (core) Allow Pods connecting to Host services smoothly
    hostpath-storage     # (core) Storage class; allocates storage from host directory
    ingress              # (core) Ingress controller for external access
    kube-ovn             # (core) An advanced network fabric for Kubernetes
    mayastor             # (core) OpenEBS MayaStor
    metallb              # (core) Loadbalancer for your Kubernetes cluster
    metrics-server       # (core) K8s Metrics Server for API access to service metrics
    minio                # (core) MinIO object storage
    nvidia               # (core) NVIDIA hardware (GPU and network) support
    observability        # (core) A lightweight observability stack for logs, traces and metrics
    prometheus           # (core) Prometheus operator for monitoring and logging
    rbac                 # (core) Role-Based Access Control for authorisation
    registry             # (core) Private image registry exposed on localhost:32000
    rook-ceph            # (core) Distributed Ceph storage using Rook
    storage              # (core) Alias to hostpath-storage add-on, deprecated




Step 2.6: Enable Common Services
    ```bash
    sudo microk8s enable dns 
    sudo microk8s enable dashboard 
    sudo microk8s enable storage
    ```
    

## Step 3: Startup Kubernetes

Step 3.1: Access Kubernetes Dashboard

```bash
    microk8s dashboard-proxy &
```

This will start the dashboard and display the local url. 
e.g. https://127.0.0.1:10443
Note down also the token displayed in the console to login to the dashboard. 

![Kubernetes Dashboard](./../images/microk8s-dashboard.png)

In case you missed the note the token, you can get it at any time using the following command:

```bash
    # Get the token for accessing the dashboard
    token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
    microk8s kubectl -n kube-system describe secret $token
```

Step 3.2: Open the daskboard in your browser.

Open your browser and navigate to `https://localhost:10443`. Use the token obtained from the above command to log in.


Step 3.3: Create aliases as functions for convenience

    ```bash
    echo 'mk() { microk8s "$@"; }' >> ~/.bashrc
    echo 'mkl() { microk8s kubectl "$@"; }' >> ~/.bashrc
    source ~/.bashrc
    ```
    Also, add to root's .bash in case if you are using sudo
    ```
    sudo vi /root/.bashrc 
    ```
    Note: If mkl is giving permission issues, then add the user again to microk8s group. Step 2.3. and 2.4.

Step 3.4: Export the MicroK8s kubeconfig to your default kubeconfig file:
    ```bash
    microk8s config > ~/.kube/config
    ```

You have successfully installed microk8s on WSL2 Ubuntu on Windows.

> **Note:**
> - This script installs MicroK8s using the snap package manager.
> - Snap is a software packaging and deployment system developed by Canonical for the Linux operating system. It allows developers to distribute their applications directly to users in a secure and isolated environment.
> - The `--classic` option is used to install the snap in classic confinement mode, which gives the application full access to the system, similar to traditional Linux package managers. This is necessary for applications that require extensive interaction with the system, such as MicroK8s.
> - Adding aliases for `microk8s` and `microk8s kubectl` commands can save time and make it easier to work with MicroK8s.
> - Adding functions for `mk` and `mkl` ensures that all command options for `microk8s` and `microk8s kubectl` are resolved correctly.
