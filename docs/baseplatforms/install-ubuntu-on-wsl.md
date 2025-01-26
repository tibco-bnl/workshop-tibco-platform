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

If the Ubuntu image is already installed you should see it listed im the output.
wsl -l -v
  NAME              STATE           VERSION
* Ubuntu-22.04      Stopped         2

If ubuntu is listed, proceed to step 2.3 otherwise install the Ubuntu image with the following command:

```powershell
wsl --install Ubuntu
```


Step 2.3: Create a copy of the Ubuntu image to be used for the platform
In this step we will create a copy of the Ubuntu image to be used for the platform. Create a batch file named "install-tibco-platform.bat" and populate it with the following script.


```powershell
@echo off

IF NOT EXIST "tmp" (
  mkdir tmp
)

wsl --terminate Ubuntu-22.04
if %errorlevel% equ 0 (
    echo Terminated WSL Ubuntu-22.04 
) else (
    echo Ubuntu not found, make sure the Ubuntu-22.04 is installed!!
    exit
)

echo Exporting Ubuntu-22.04.... this may take a minute 
wsl --export Ubuntu-22.04 tmp\ubuntuimage.tar 

if %errorlevel% equ 0 (
    echo Saved Ubuntu-22.04 image
    ) else (
        echo Unable to save Ubuntu-22.04 image. Make sure it is installed and named Ubuntu-22.04!!
)


IF EXIST "tmp\ubuntuimage.tar" (
    echo Creating tibcoplatform image
    wsl --import tibcoplatform . .\tmp\ubuntuimage.tar
    if %errorlevel% equ 0 (
        echo An image named 'tibcoplatform' was created successfully.
    ) else (
        echo Failed to create an image named 'tibcoplatform'. 
    )
)

del /f /s /q ".\tmp\*"
rmdir /s /q ".\tmp"

```

Step 2.4: Check if the image is installed by running the following command:

```powershell
    wsl -l -v
```

The list must contain 'tibcoplatform'

wsl -l -v
  NAME              STATE           VERSION
* docker-desktop    Stopped         2
  Ubuntu-22.04      Stopped         2
  tibcoplatform     Stopped         2
  minikube          Stopped         2