# How to demo Controltower in the Benelux control plane.

In the Benelux control plane (https://tibcoatseuwe1.eu-west.my.tibco.com/) a control tower dataplane has been setup for demo purposes.<br><br>
Currently we have BW5 domains and EMS instances connected to this control tower <br>(dataplane name ControlTower: https://tibcoatseuwe1.eu-west.my.tibco.com/cp/app/ct?dp_id=d3n14mr9sqls73eol01g)<br>
<br>
The BW5 domains and EMS instances are running on EC2 instances. <br>
The BW5 and EMS services will start upon boot time of the EC2 instance via systemd services.<br>
<br>
The EC2 instances (eu-west-1) are:<br>
- NL_ControlTower   (i-0d272dcdd9fd76b95)<br>
- NL_ControlTower_2 (i-09322b36ac1438fe2)<br>

These instances will automatically shutdown at 6pm CET via a cronjob (sudo crontab -e).
Starting these instances in the AWS Console is sufficient to start all tibco services and connect to control tower.

## Accessing the EC2 instances
### Networking
Both instances use the same security group which are used to allow access. <br>
Security group id: sg-004060ed6e0a54f68.
To allow ssh access from your current ip address update this security group.<br>
Please don't change the inbound rules with the Description 'AKS cluster Control Tower 172.201.41.9'. This will allow access from the ControlTower dataplane deployed on our AKS K8S cluster.

### SSH access
SSH access is key based access.
To add a public key for ssh access follow below steps:

1) Select your instance in the console and click Connect. 
2) Choose the EC2 Instance Connect tab and click Connect to open a browser-based terminal.
3) Once inside, run: nano ~/.ssh/authorized_keys<br>
Paste your Public Key (the one ending in .pub) on a new line.<br>
Save and exit (Ctrl+O, Enter, Ctrl+X).<br>

Now the instance can be accessed via ssh using the private key associated to the public key.
