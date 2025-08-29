# Control Tower installation on Azure AKS cluster - Setup Guide

## References

- [TIBCO Documentation Control Plane Overview](https://docs.tibco.com/pub/platform-cp/1.9.0/doc/html/Default.htm#Subsystems/platform-ct/user-guide/control-tower-overview.htm?TocPath=Managing%2520Control%2520Tower%2520Data%2520Planes%257C_____1)


---

## General

This guide described the setup of a Control Tower data plane on an Azure AKS cluster.
The creation of the Control Tower is initiated from the Control Plane UI (create dataplane) and excuted by a set of helm commands created during this initialisation.


## 1 Create storage class 

The storage class needs some specific mount options in order for the hawk-console and msg-gateway to share the same persistant volume using SQLLite.

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azurefile-csi-premium-ct
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    k8slens-edit-resource-version: v1
    kubernetes.io/cluster-service: 'true'
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Delete
mountOptions:
  - mfsymlinks
  - actimeo=30
  - nosharesock
  - nobrl
  - dir_mode=0777
  - file_mode=0777
  - noperm
allowVolumeExpansion: true
volumeBindingMode: Immediate
```

The name of the storage class can be adjusted as per company requirements.

## 2 Create dataplane

In the Control Plane UI follow the below procedure:<br>

- Click 'Data Planes'<br>
- Click 'Register a Data Plane' <br>
- Click 'Control Tower Data Plane' Start<br>
This opens the Setup Control Tower wizard:<br>
<br>

- Data Plane Details:<br>
    > 'Data Plane Name': name of the data plane to be used for Control Tower<br>
    > 'Description' : description of the data plane, will be displayed on the data plane overview page<br>
    > 'Machine Host Name' : the fqdn used for the ingress into the dataplane<br>
    > 'I have read and accepted the TIBCO EUA': check this<br>
    > Click 'Proceed with Advanced Configuration' <br>

- Namespace & Service Account:<br>
    > 'Namespace': name of the namespace to be used for the control tower deployment (will be created)<br>
    > 'Service Account': name of the service account to be used for the control tower deployment (will be created)<br>
    > Click 'Next' <br>

- Resources:<br>
    Storage Class:<br>
    > Resource Name:  name of the storageclass (change as per liking)<br>
    > Description:  description (change as per liking)<br>
    > Storage Class Name: use the name of the storage class created in the previous section.<br>
    > Click 'Next' <br>

    Ingress Controller:<br>
    > Ingress Controller: nginx<br>
    > Resource Name: name of the resource. <br>
    > Ingress Class name: This should be the same as the main nginx ingress of the K8S cluster if there is already a running data plane running on this K8S cluster. <br>
    > hostname.tibco.com<br>
    > FQDN: prepopulated based on 'Machine Host Name' provided on the Data Plane Detais screen.<br>
    > Click 'Next' <br>

- Configuration:<br>
    > Details on this page are usually used as per default settings (originating from the CP configuration)<br>
    > Click 'Next' <br>

- Preview:<br>
    > Check all information provided<br>
    > Click 'Register on Control Plane' <br>
<br>
Now Click 'Display Details & Registration Commands'.

Execute the 4 provided commands against the K8S cluster to create the 'Control Tower' Data Plane
Wait a few minutes for all the deployments to complete and pods to startup.


## Add BW5 domain to Control Tower

Open the Control Tower dataplane, click on 'Data Plane Configuration'.
On the domain Tab Click Add Domain.

- 'Add Domains details'.
> Domain name: name of the existing BW5 domain<br>
> Transport: Select EMS or RV based on the domain communication within the domain uses.<br>
EMS: provide the ems details of the ems server used for domain communication<br>
> EMS Server URL<br>
> EMS Username<br>
> EMS Password<br>

RV: <br>
> Hawk RV service: port number of the Hawk RV service on the BW5 server<br>
> Hawk RV Network: name of the Hawk RV Network on the BW5 server<br>
> Hawk RV Daemon: rv daemon connection string (i.e. tcp://<bw server>:<rv deamon port>)<br>

Click 'Add Domain' 

This will conect the Control Tower to the BW domain. After a while domain details will become visible in the Control Tower Data Plane.



## BW5 app configuration

To enable the BW5 application to start producing metrics and traces some additions to the bw tra file need to be made.

```java.property.bw.engine.opentelemetry.enable=true
java.property.otel.exporter.otlp.traces.protocol=http/protobuf
java.property.bw.engine.opentelemetry.disableAutoConfiguration=false
java.property.bw.engine.opentelemetry.span.exporter=OTLP-HTTP
java.property.bw.engine.opentelemetry.traces.enable=true
java.property.otel.exporter.otlp.traces.endpoint=https://{{ FQDN }}/tibco/agent/o11y/d2mn70s4inpc73cvg35g/traces
java.property.bw.engine.opentelemetry.metrics.enable=true
java.property.otel.exporter.otlp.metrics.protocol=http/protobuf
java.property.otel.exporter.otlp.metrics.endpoint=https://{{ FQDN }}/tibco/agent/o11y/d2mn70s4inpc73cvg35g/metrics
```


Update the {{ FQDN }} with the 'Machine Host Name' as provided during the Register data plane procedure in CP UI.

These properties need to be added in the file $TIBCO_HOME/bw/5.16/bin/bwengine.tra . After this any application being deployed will have these properties.
For existing deployed applications these properties need to be added by either: <br>
1) update the application .tra file in the domain/application directory and restart it.
2) perform a forced deployment

