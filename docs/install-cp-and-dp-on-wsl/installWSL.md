# Install WSL and an Ubuntu image

The TIBCO plaform can be installed on Windows when using "Windows Subsystem for Linux". This document contains a description on how to install WSL and Ubuntu

## Step 1: Install WSL

Step 1.1: Make a directory (for example 'tibcoplatform)
a) Open a Powershell in admin mode
b) Create a new directory and go to this directory

```powershell
mkdir tibcoplatform
cd tibcoplatform
```


Step 1.2: Check if WSL2 is installed
In some cases WSL may already be installed. In order to check this open powershell as an administrator and run the following command:
```powershell
wsl --version
```

Make sure the version is 2.x.
If this is the case move on to step 2.


Step 1.3: Install WSL
Run the following command to enable the WSL feature:
```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Step 1.4: Enable the Virtual Machine Platform feature:
```powershell
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Step 1.5 Restart your computer to apply the changes.

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