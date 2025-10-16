# How to mount a license file as a secret in a BusinessWorks (6) container

For in product activation of the business works product a license file need to be added to the bw container in order for the bw engine to validate the license.
This how to desribes the steps required to enable this.

There are several steps which will be executed:

1) Create kubernetes secret from the license file
2) Add a volume to the helm configuration
3) Add a volume mount to the helm configuration
4) Add a value helm configuration to set the environment variable use by bw to locate the mounted license file


## 1 Create kubernetes secret from the license file

It is assumed that the license file has been created and downloaded from the tibco license application.
The file will have an extention of .bin.

Instruction to create the secret

```
kubectl  create secret generic license-file -n {{dataplane namespace}} --from-file={{full path to local license.bin file}}
```
Here the name of the secret is 'license-file'. 
This name can be changed if required, but that change need to be reflected in the step 2, secretName

## 2 Add a volume to the helm configuration

The helm configuration from the application which is (being) deployed needs to be updated with the following volume configuration.
Section Volumes in the helm configuration.
```
volumes:
- name: license-volume
  secret:
    defaultMode: 420
    optional: false
    secretName: license-file
```
## 3 Add a volume mount to the helm configuration

To mount this volume into the bw container add the following configuration to the bwapps.volumemounts

```
  volumeMounts:
  - mountPath: /temp/
    name: license-volume
```

## 4 Add a value helm configuration to set the environment variable use by bw to locate the mounted license file

To instruct the businessworks engine where to locate the license file the follow configuration needs to be added to the helm chart configuration:

```
dpConfig:
  activationServiceUrl: /temp
```


This will complete the setup for in production license setup for a businessworks container.
Update the configuration or deploy with this configuration.

