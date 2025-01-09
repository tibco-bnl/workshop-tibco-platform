
# Install docker desktop on WSL 

The following steps need to be taken to install Docker Desktop on WSL:

Prerequisite: 
1) Have Visual Studio Code installed on Windows. If it is not installed, do so. See for details: https://code.visualstudio.com/download
2) Have Windows Subsystem 2 for Linux installed. If you don't have it installed / enabled, please do so. See for details: https://learn.microsoft.com/en-us/windows/wsl/install
3) Have the WSL extention for Visual Code installed. See for details: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl


## Step 1: Install Docker Desktop for Windows Subsystem for Linux (WSL)

See for detailled instructions [here](https://docs.docker.com/desktop/setup/install/windows-install/). Please mind: use an installation on WSL, NOT on Hyper-V.

## Step 2: Enable Kubernetes on Docker Desktop

Step 2.1: Open Docker Desktop and click Click settings --> Kubernetes
![](../images/DockerDesktop1.png)

Step 2.2: enable kubernetes
Set 'enable Kubernetes' en click 'Apply & Restart'
![](../images/DockerDesktop2.png)
Wait for Kubernetes to start.

Please mind: if you previously used kubernetes, you can refesh the setup by clicking the button 'reset kubernetes cluster'.

Step 2.2: Test kubernetes
Open a command prompt and type 'kubectl get namespaces'. 
Check if you get a list of available namespaces.

## Step 3: Prepare the Ubuntu image
The (standard) Ubuntu image provided as part of WSL will be used to run the installation script. In order to do so, a number of modifications need to made.

Step 3.1: Check if the standard WSL Ubuntu ../images is installed. 

a) Open a windows terminal
b) Run the following command

```windows terminal
wsl -l -v
```
c) Make sure the standard ubuntu image is listed:

NAME              STATE           VERSION
* Ubuntu            Running         2
  docker-desktop    Running         2

d) If it is not run the following command
```windows terminal
wsl -l -o
```

Make sure Ubuntu is in the list.

e) Install the image with the following command
```windows terminal
wsl --install -d Ubuntu
```

Step 3.2 Login to the Ubuntu WSL image
a) Run the following command
```windows terminal
wsl -d ubuntu 
```
b) Go to your home directory
```bash
cd ~ 
```

c) Create a work directory named 'tibcoplatform'
```bash
mkdir tibcoplatform
cd tibcoplatform 
```

Step 3.3 Install required software

a1) Check if 'git' is installed
```bash
git --version
```
a2) If it isn't, install it with the following commands:
```bash
sudo apt update
sudo apt install git
```

b1) Check if kubectl is installed
```bash
kubectl version
```

b2) If it is not installed, install it:
```bash
sudo apt update
sudo apt install kubectl
```

c1) Check if helm is installed
```bash
helm version
```

c2) If it is not installed, install it:
```bash
sudo apt update
sudo apt install helm
```

d1) Check if yq is installed
```bash
yq version
```
d2) If it is not installed, install it:
```bash
sudo apt update
sudo apt install yq
```

```