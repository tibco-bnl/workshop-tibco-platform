# Install the TIBCO control plane + data plane on microK8s on WSL

This document contains a description to install the control plane + data plane on micro8s on WSL


## Step 1: start the Ununtu image
If you haven't done so already: Open a command prompt, go to the directory created during the installation of WSL and the Ubuntu image and run the following command:
```windows terminal
wsl -d tibcoplatform
```

You will be transferred to a terminal that runs on the Ubuntu WSL image earlier created. All commands from this moment in time are carried out on this Linux terminal.


## Step 2: Run the installation script 

Step 2.1: update and upgrade packeges
    ```bash
    /bin/bash -c "$(curl -fsSL https://github.com/tibco-bnl/workshop-tibco-platform/blob/main/scripts/run_platform_provisioner.sh)"
    ```