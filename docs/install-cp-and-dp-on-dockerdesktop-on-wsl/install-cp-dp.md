# Install the TIBCO control plane + data plane on microK8s on WSL

This document contains a description to install the control plane + data plane on Docker Desktop for WSL


## Step 1: start the WSL Ununtu image

Step 1.1: If you haven't done so already, open a command prompt.
Create an installation directory (c:\tibcoplatform)

```windows terminal
mkdir c:\tibcoplatform
```

Step 1.2: Go to this directory
```windows terminal
mkdir c:\tibcoplatform
```


Open the a WSL linux image by running the following command:
```windows terminal
wsl -d Ubuntu-22.04
```

You will be transferred to a terminal that runs on the basic Ubuntu WSL image. All commands from this moment in time are carried out on this Linux terminal.


## Step 2: Run the installation script 

Step 2.1: update and upgrade packeges
    ```bash
    /bin/bash -c "$(curl -fsSL https://github.com/tibco-bnl/workshop-tibco-platform/blob/main/scripts/run_platform_provisioner.sh)"
    ```