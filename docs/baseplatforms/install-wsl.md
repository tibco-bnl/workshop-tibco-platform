# Install WSL

The TIBCO plaform can be installed on Windows when using "Windows Subsystem for Linux". This document contains a description on how to install WSL

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
