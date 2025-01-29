# Install Ubuntu on WSL

An Ubuntu image on WSL can be used as host for the TIBCO Platform. This document contains a description on how to install a fresh instance of ubuntu on WSL.



## Step 1: Install WSL
If you don't have WSL running, install WSL2 (on Windows) first. [See for a description here](install-wsl.md).

## Step 2: Install a fresh Ubuntu image

Run the following steps in a powershell with admin rights

Step 2.1: Check if an Ubuntu image is installed already and if needed install it.
```powershell
wsl -l -v
```
![output](../images/wsl-l-v.png)

Step 2.2: Check if Ubuntu-24.04 is installed.<br> 
If it is not install it 

```powershell
wsl --install Ubuntu-24.04
```

Step 2.3: Check if the image is installed by running the following command:

```powershell
    wsl -l -v
```


```powershell
wsl -l -v
  NAME              STATE           VERSION
* docker-desktop    Stopped         2
  Ubuntu-24.04      Stopped         2
  ```