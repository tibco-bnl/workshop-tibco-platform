# Install Ubuntu on AWS

An Ubuntu image on AWS can be used as the base platform for TIBCO platform. The following steps are required to install an Ubuntu image

## Step 1
Install an Ubuntu (24-04) image in AWS. Use a server with at least 8 CPUs and 32 GB ram

## Step 2
Whitelist the IP address of your workstation for access on port 22 (ssh) and 3389 (RDP)

## Step 3
Configure putty (or any other SSH client) to access the server over SSH.

## Step 4: Install GNOME and XRDP
Remark: The following was tested on Azure but not yet on AWS
In this step we will install the XRDP service and the GNOME GUI, which will enable users to login via Windows Remote Desktop.

Step 4.1: Login to the server via SSH (Putty). See for details the previous step.

Step 4.2: Install Gnome

```bash
sudo apt update
sudo apt install gnome gnome-shell 
sudo apt install gdm3
```

Step 4.3: Start GNOME
```bash
sudo systemctl start gdm3.service
sudo dpkg-reconfigure gdm3
```

Step 4.4: Install xrdp
```bash
sudo apt-get -y install xrdp
sudo systemctl enable xrdp
```

Step 4.5: Configure additional security settings

```bash
sudo adduser xrdp ssl-cert
sudo adduser tibco
sudo bash -c 'echo "tibco ALL=(ALL:ALL) ALL" >> /etc/sudoers'
```

Step 4.6: Restart xrdp
```bash
sudo systemctl restart xrdp
```
