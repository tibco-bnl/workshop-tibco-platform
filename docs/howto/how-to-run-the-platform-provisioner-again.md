# how to run the platform provisioner again

The platform provisioner is a tool that can be used to provision the platform and to monitor provisioning steps.
After a shutdown of the VM, the platform provisioner is no longer available because the required port forwaring is lost.
To setup the port forwarding (for port 8080) run the following command: 


```bash
~/projects/platform-dev/workshop-tibco-platform/scripts/port_forwarder.sh provisioner
```

After that you can open the platform provisioner again at http://localhost:8080/

