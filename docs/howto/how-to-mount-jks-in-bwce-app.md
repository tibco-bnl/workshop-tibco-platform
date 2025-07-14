# How to mount a JKS (secret) in an BWCE container 

This how to describes how to mount a JKS keystore file into a BWCE container in a pipeline context.

Preparation/setup
Encode jks to create a text based secret


> cat amqp-keystore.jks | base64 -w 0

Output = <BASE64_ENCODED_JKS_CONTENT>:

Store this as variable in the CICD secret store
Or any other secret store (NOT GIT!!!!)

Store yaml to create secret in git
# kubernetes jks secret
apiVersion: v1
kind: Secret
metadata:
  name: amqp-keystore
type: Opaque
data:
  amqp-keystore.jsk: <BASE64_ENCODED_JKS_CONTENT>

Store bwce app deployment values yaml in git
https://github.com/TIBCOSoftware/tp-helm-charts/blob/main/charts/dp-bwce-app/values.yaml

Replace the volumes section with the volume specification for the BWCE app:
From:
volumes: []
To:
Volumes:
- name: amqp-keystore
  secret:
    secretName: amqp-keystore-secret
      items:
      - key: keystore.jsk
        path: keystore.jsk

Replace the bwapp.volumeMounts[] section with
From:
bwapp:
  volumeMounts[]
To: 
bwapp:
  volumeMounts:
  - name: amqp-keystore
    mountPath: /mnt/keystore
    readOnly: true


Pipeline
Create Kubernetes secret
Pull value of secret variable from CICD secret store
Replace <BASE64_ENCODED_JKS_CONTENT> with content of secret variable in yaml
Apply yaml to dataplane (k apply -n <dataplane name> -f <name of secret yaml>)


Build/deploy app 
(assuming ear file has been created)
Invoke BWCE-capability API to build (v1/dp/builds) 
This will return the buildId.


Invoke BWCE-capability API to Generate values.yaml from an app Build (v2/dp/builds/{buildId}/values?minimal=false)
This will return the complete values.yaml file 


Merge the data from the stored deployment values.yaml data with the complete values.yaml file to construct one values.yaml file including the jks mount details. (complete_values.yaml)


Invoke BWCE-capability API to deploy the app release (v2/dp/deploy/release)
Use the complete_values.yaml as deployment input to specify and mount the volume.






