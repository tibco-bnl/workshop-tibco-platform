# TIBCO Platform Control Plane on AKS



## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
  
- [1. Create Ingress Namespace](#1-create-ingress-namespace)
- [2. Create Default TLS Secret in Ingress namespace](#2-create-default-tls-secret-in-ingress-namespace)
- [3. Install Ingress Controller as a Load Balancer](#3-install-ingress-controller-as-a--load-balancer)
- [4. Install Storage](#4-install-storage)
- [5. Create CP Namespace](#5-create-cp-namespace)
- [6. Create CP Service Account](#6-create-cp-service-account)
- [7. Create CP DB Password Secret](#7-create-cp-db-password-secret)
- [8. Create CP DB TLS Certificate Secret [Optional]](#8-create-cp-db-tls-certificate-secret-optional)
- [9. Create Session Keys Secret](#9-create-session-keys-secret)
- [10. Install Platform Bootstrap](#10-install-platform-bootstrap)
- [11. Create CP Encryption Secret](#11-create-cp-encryption-secret)
- [12. Install Platform Base](#12-install-platform-base)
- [13. Update Core DNS](#13-update-dns)
- [14. Log into CP](#14-log-in-cp)
- [15. Create Subscription](#15-create-subscription)
- [16. Data plane creation](#16-dataplane-creation)
- [17. Deploy developer hub capability](#17-deploy-developer-hub-capability)
- [18. Developer hub post deployment configuration](#18-post-deployment-configuration)


## Prerequisites
> **_NOTE:_** Documented with TIBCO Platform 1.12.0  
1. Access to AKS K8s cluster
2. Access from the AKS K8S cluster to a PostgreSQL 16.x Database (for instance private end point)
3. Database server parameters to set:<br>
    'require_secure_transport' --> 'OFF' (To change!!!) <br>
    'max_connections' --> 150 <br>
    'azure.extensions' --> 'UUID-OSPP'
3. Access to a SMTP enabled Email Server. 
4. Identify, and register DNS names for Control Plane Router/UI, and Control Plane Tunnel.  
5. Acquire certificates to secure Control Plane Services. Certificate CN and/or SAN must match CP Router/UI, and Tunnel DNS Names.  

## Environment Variables 

### Namespaces
```bash
export TP_INGRESS_NAMESPACE=ingress-system ## Ingress System Namespace
export STORAGE_NAMESPACE=storage-system ## Storage System Namespace
export ELASTIC_NAMESPACE=elastic-system ## Elastic System Namespace
export PROMETHEUS_NAMESPACE=prometheus-system ## Prometheus System Namespace
```

### Ingress TLS Config
```bash
export TP_INGRESS_CLASS=haproxy ## Ingress Class nginx | haproxy
export DEFAULT_INGRESS_KEY_FILE=private_key.pem ## Path to Private Key in PEM format
export DEFAULT_INGRESS_CERT_FILE=public_cert.pem ## Path to Public Key in PEM format
export DEFAULT_INGRESS_TLS_SECRET=ingress-cert-secret ## Default TLS Secret for Ingress
```

### Chart Repo
```bash
export TP_CHART_REGISTRY="https://tibcosoftware.github.io" ## TP Helm Registry or custom 
export TP_CHART_REPO="tp-helm-charts" ## TP Helm Chart Repo
export TP_CHART_REPO_USER_NAME="repo-user" ## TP Helm Chart Repo User. Ignore for public repo
export TP_CHART_REPO_TOKEN="repo-passwd" ## TP Helm Chart Repo Password. Ignore for public repo
export IS_OCI=false ## Set true for OCI repo
```

### Image Repo
```bash
export CP_CONTAINER_REGISTRY="csgprduswrepoedge.jfrog.io" ## TP Image Registry, default TIBCO JFrog
export CP_CONTAINER_REGISTRY_REPOSITORY="tibco-platform-docker-prod"  ## TP Image Repo, default TIBCO JFrog
export CP_CONTAINER_REGISTRY_USERNAME="image-registry-user" ## TP Image Registry User, TIBCO JFrog Credentials from CP SaaS
export CP_CONTAINER_REGISTRY_PASSWORD="image-registry-password" ## TP Image Registry User, TIBCO JFrog Credentials from CP SaaS
```

### Storage
```bash
export RWO_STORAGE_CLASS=azure-disk-sc ## Disk Storage Class
export RWO_STORAGE_SKU=Premium_LRS ## Disk Storage SKU
export RWX_STORAGE_CLASS=azure-files-sc ## Fileshare Storage Class
export RWX_STORAGE_SKU=Premium_LRS ## Fileshare Storage Class
export STORAGE_RECLAIM_POLICY=Retain ## Fileshare Storage Class
```

### Database
```bash
export CP_DB_HOST="db.postgres.database.com" ## CP Postgress DB
export CP_DB_PORT="5432" ## CP Postgres DB Port
export CP_DB_SECRET_NAME="cp-db-secret" ## CP DB Secret
export CP_DB_SSL_MODE="disable" # verify-full, disable. Disable is required since DevHub does not support SSL. Azure db server parameter 'require_secure_transport' should be set to 'OFF'
export CP_DB_USER_NAME="db-user" ## CP DB User
export CP_DB_PASSWORD='db-password' ## CP DB Password
export CP_DB_NAME="postgres" ## CP default DB

### Database SSL Config
export CP_DB_SSL_ROOT_CERT_SECRET_NAME="cp-db-ssl" ## CP SSL Secret
export CP_DB_SSL_ROOT_CERT_FILENAME="cp_db_ssl.cert" ## CP SSL Filename
export CP_DB_SSL_ROOT_CERT_FILE="db_ssl.pem" ## CP SSL File name and path in PEM format
```

### CP Bootstrap Config
```bash
### CP Config
export CP_INSTANCE_ID="cp1" ## CP Instance ID
export CP_NAMESPACE="${CP_INSTANCE_ID}-ns" ## CP Namespace

export CP_PLATFORM_BOOTSTRAP_VERSION="1.11.0" ## CP Bootstrap Chart Version

export CP_NODE_CIDR="10.4.0.0/16" ## Node Subnet CIDR
export CP_POD_CIDR="10.4.0.0/20"  ## K8s Pod CIDR
export CP_SERVICE_CIDR="10.0.0.0/16" ## K8s Service CIDR
export TP_BASE_DNS_DOMAIN="tibco.example.com" ## TP base domain
export CP_SERVICE_DNS_DOMAIN="cp.${TP_BASE_DNS_DOMAIN}" ## CP Router/UI DNS domain
export CP_TUNNEL_DNS_DOMAIN="tunnel.${TP_BASE_DNS_DOMAIN}" ## CP Tunnel DNS domain 
export CP_SUBSCRIPTION="dev" ## CP Subscription Name
export CP_STORAGE_PV_SIZE="10Gi" ## CP PV Size
```

### CP Base Config
```bash
export CP_PLATFORM_BASE_VERSION=1.11.0 ## CP Base Chart Version
export CP_ADMIN_CUSTOMER_ID="customerID" ## Customer ID, available on SaaS CP

## CP Email Config
export CP_MAIL_SERVER_ADDRESS="mail.smtp-server.com" ## SMTP Server
export CP_MAIL_SERVER_PORT_NUMBER=25 ## SMTP Port
export CP_MAIL_SERVER_USERNAME="" ## SMTP User
export CP_MAIL_SERVER_PASSWORD="" ## SMTP Password
export CP_FROM_REPLY_TO_EMAIL="platform-admin@customer.com" ## Platform Invitation Email. Must be valid email domain
export CP_ADMIN_EMAIL="platform-admin@customer.com" ## CP Admin Email
export CP_ADMIN_INITIAL_PASSWORD="adminpassword" ## CP Admin Initial Password, if enabled
```

### Adjust for HTTPS/OCI Helm Repo
```bash
if [ "$IS_OCI" = true ] ; then
    HELM_URL="${TP_CHART_REGISTRY}/${TP_CHART_REPO}/"
else
   HELM_URL="--repo ${TP_CHART_REGISTRY}/${TP_CHART_REPO} "
fi
```

## 1. Create Ingress Namespace (when haproxy ingress is not present in the k8s cluster)
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${TP_INGRESS_NAMESPACE}
  # labels:
  #   networking.platform.tibco.com/non-dp-ns: enable
EOF
```

## 2. Create Default TLS Secret in Ingress namespace (when haproxy ingress is not present in the k8s cluster)
Starting 1.4.0 certificates signed by Well-Known CA is not mandatory [Reference: Using Custom Certificates](https://docs.tibco.com/pub/platform-cp/latest/doc/html/UserGuide/using-custom-certificate.htm)
```bash
kubectl create secret tls ingress-cert-secret \
    -n  ${TP_INGRESS_NAMESPACE} \
    --key ${DEFAULT_INGRESS_KEY_FILE} \
    --cert ${DEFAULT_INGRESS_CERT_FILE}
```

## 3. Install Ingress Controller as a  Load Balancer (when haproxy ingress is not present in the k8s cluster)

### HAPROXY:

```bash
helm upgrade --install --wait --timeout 1h --create-namespace  \
  -n  ${TP_INGRESS_NAMESPACE} haproxy-ingress haproxy-ingress \
  --repo "https://haproxy-ingress.github.io/charts" --version 0.14.7 --set controller.service.http.disabled=true -f - <<EOF
controller:
  logs:
    enabled: "true" ## Enable  access logs
  service:
    type: LoadBalancer
    loadBalancerSourceRanges: 
    - ${TP_AUTHORIZED_IP_RANGE} # allow only authorized IP Range
    - 108.202.252.33/32
    - ${CP_POD_CIDR} # allow Data Plane Pod access via Ingress Load Balancer service
    annotations: 
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: '/healthz'
      # service.beta.kubernetes.io/azure-load-balancer-internal-subnet: $AKS_SUBNET ## Enable for Private Load Balancer
      # service.beta.kubernetes.io/azure-load-balancer-internal: 'true' ## Enable for Private Load Balancer  
  ingressClass: ${TP_INGRESS_CLASS}
  ingressClassResource:
    enabled: true
  config:
    ssl-always-add-https: "true" #https://haproxy-ingress.github.io/docs/configuration/keys/#ssl-always-add-https
  extraArgs:
    default-ssl-certificate: ${TP_INGRESS_NAMESPACE}/${DEFAULT_INGRESS_TLS_SECRET}
EOF
```

#### Retrieve external-ip of Ingress (when haproxy ingress is not present in the k8s cluster)

``` bash
 kubectl --namespace ingress-system get services haproxy-ingress -o wide 
```



### Test HA Proxy Ingress (when haproxy ingress is not present in the k8s cluster)
```bash
## deployment app and service
kubectl --namespace ${TP_INGRESS_NAMESPACE} create deployment echoserver --image k8s.gcr.io/echoserver:1.3
kubectl --namespace ${TP_INGRESS_NAMESPACE} expose deployment echoserver --port=8080

## validate app is running
kubectl -n ${TP_INGRESS_NAMESPACE} get pod -w

## expose app service on ingress
kubectl --namespace ${TP_INGRESS_NAMESPACE} create ingress echoserver \
  --class=$TP_INGRESS_CLASS \
  --rule="echoserver.${TP_BASE_DNS_DOMAIN}/*=echoserver:8080,tls"

## test access
curl -k https://echoserver.$TP_BASE_DNS_DOMAIN

## cleanup
kubectl delete --namespace ${TP_INGRESS_NAMESPACE} ingress echoserver
kubectl delete --namespace ${TP_INGRESS_NAMESPACE} service echoserver
kubectl delete --namespace ${TP_INGRESS_NAMESPACE} deployment echoserver
```


## 4. Install Storage (when storage classes described in environment sections are not present in the k8s cluster)
```bash
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
  --username ${TP_CHART_REPO_USER_NAME} --password ${TP_CHART_REPO_TOKEN} \
  -n ${STORAGE_NAMESPACE} dp-config-aks-storage \
  ${HELM_URL}dp-config-aks --version "1.6.0" -f - <<EOF
clusterIssuer:
  create: false
storageClass:
  azuredisk:
    enabled: true
    name: ${RWO_STORAGE_CLASS}
    reclaimPolicy: ${STORAGE_RECLAIM_POLICY}
    volumeBindingMode: Immediate
    parameters:
      skuName: ${RWO_STORAGE_SKU}
  azurefile: 
    enabled: true
    name: ${RWX_STORAGE_CLASS}
    reclaimPolicy: ${STORAGE_RECLAIM_POLICY}
    volumeBindingMode: Immediate 
    parameters:
      skuName: ${RWX_STORAGE_SKU}
      allowBlobPublicAccess: "false"
      networkEndpointType: privateEndpoint
    mountOptions:
      - mfsymlinks
      - cache=strict
      - nosharesock
EOF
```


## 5. Create CP Namespace
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${CP_NAMESPACE}
  labels:
    app.cloud.tibco.com/content: tibco-core
    platform.tibco.com/controlplane-instance-id: ${CP_INSTANCE_ID}
EOF
```

## 6. Create CP Service Account
[Reference: Permissions Required by the Role ](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Installation/rbac-permissions.htm)
```bash
kubectl create -n  ${CP_NAMESPACE} serviceaccount ${CP_INSTANCE_ID}-sa
```


## 7. Create CP DB Password Secret
```bash
kubectl apply -f - <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: ${CP_DB_SECRET_NAME}
  namespace: ${CP_NAMESPACE}
data:
  PASSWORD: $(echo ${CP_DB_PASSWORD} | base64) 
  USERNAME: $(echo ${CP_DB_USER_NAME} | base64)
type: Opaque
EOF
```


## 8. Create CP DB TLS Certificate Secret [Optional only if ssl is enabled]
Required for SSL enabled Databases, where SSL Mode is not set to _disable_
[Reference: Creating K8s Secret for SSL enabled DB](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Installation/creating-secret.htm)
```bash
kubectl apply -f -  <<EOF
apiVersion: v1
kind: Secret
data:
  ${CP_DB_SSL_ROOT_CERT_FILENAME}: $(cat ${CP_DB_SSL_ROOT_CERT_FILE} | base64 -w 0)
metadata:
  annotations:
    helm.sh/hook: "pre-install, pre-upgrade"
    helm.sh/hook-weight: "0"
  name: ${CP_DB_SSL_ROOT_CERT_SECRET_NAME}
  namespace: ${CP_NAMESPACE}
type: Opaque
EOF
```

## 9. Create Session Keys Secret

```bash
kubectl create secret generic session-keys -n ${CP_NAMESPACE} \
  --from-literal=TSC_SESSION_KEY=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c32) \
  --from-literal=DOMAIN_SESSION_KEY=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c32)
```

## 10. Install Platform Bootstrap 

##  HAProxy IC

```bash
helm upgrade --install --wait --timeout 1h --create-namespace  \
  --username ${TP_CHART_REPO_USER_NAME} --password ${TP_CHART_REPO_TOKEN} \
  -n ${CP_NAMESPACE}  platform-bootstrap    ${HELM_URL}platform-bootstrap  \
  --version "${CP_PLATFORM_BOOTSTRAP_VERSION}" -f - <<EOF
global:
  external:
    clusterInfo:
      nodeCIDR: ${CP_NODE_CIDR}
      podCIDR: ${CP_POD_CIDR}
      serviceCIDR: ${CP_SERVICE_CIDR}
    dnsDomain: ${CP_SERVICE_DNS_DOMAIN}
    dnsTunnelDomain: ${CP_TUNNEL_DNS_DOMAIN}
    storage:
      resources:
        requests:
          storage: ${CP_STORAGE_PV_SIZE}
      storageClassName: ${RWX_STORAGE_CLASS}
  tibco:
    containerRegistry:
      url: ${CP_CONTAINER_REGISTRY}
      repository: ${CP_CONTAINER_REGISTRY_REPOSITORY}      
      username: ${CP_CONTAINER_REGISTRY_USERNAME}    
      password: ${CP_CONTAINER_REGISTRY_PASSWORD}
    controlPlaneInstanceId: ${CP_INSTANCE_ID}
    #createNetworkPolicy: false    
    logging:
      fluentbit:
        enabled: false
    serviceAccount: ${CP_INSTANCE_ID}-sa                
hybrid-proxy:
  enabled: true
  enableWebHooks: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
  ingress:
    enabled: true
    annotations:
        haproxy-ingress.github.io/headers: "X-Forwarded-Port: 443" # default ingress https-port
    ingressClassName: ${TP_INGRESS_CLASS}         
    hosts:
      - host: '${CP_SUBSCRIPTION}.${CP_TUNNEL_DNS_DOMAIN}'
        paths:
          - path: /
            pathType: Prefix
            port: 105        
otel-collector:
  enabled: false
resource-set-operator:
  enabled: true
  enableWebHooks: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
router-operator:
  enabled: true
  enableWebHooks: false
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
  ingress:
    enabled: true
    annotations:
        haproxy-ingress.github.io/headers: "X-Forwarded-Port: 443" # default ingress https-port
    ingressClassName: ${TP_INGRESS_CLASS}   
    hosts:
      - host: '${CP_SUBSCRIPTION}.${CP_SERVICE_DNS_DOMAIN}'
        paths:
          - path: /
            pathType: Prefix
            port: 100
      - host: 'admin.${CP_SERVICE_DNS_DOMAIN}'
        paths:
          - path: /
            pathType: Prefix
            port: 100                      
EOF
```

## 11. Create CP Encryption Secret
> **_NOTE:_** REQUIRED from 1.9.0
```bash
kubectl create secret -n ${CP_NAMESPACE} generic cporch-encryption-secret --from-literal=CP_ENCRYPTION_SECRET_KEY=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c44)
```

## 12. Install Platform Base
> **_NOTE:_** Before executing base install, ensure workloads in the cluster can access external resources like Database, Email Server
```bash
helm upgrade --install --wait --timeout 1h --create-namespace  \
  --username ${TP_CHART_REPO_USER_NAME} --password ${TP_CHART_REPO_TOKEN} \
  -n ${CP_NAMESPACE}  platform-base    ${HELM_URL}platform-base  \
  --version "${CP_PLATFORM_BASE_VERSION}" -f - <<EOF
global:
  tibco:
    logging:
      fluentbit:
        enabled: false  
    containerRegistry:
      url: ${CP_CONTAINER_REGISTRY}
      repository: ${CP_CONTAINER_REGISTRY_REPOSITORY}      
      username: ${CP_CONTAINER_REGISTRY_USERNAME}    
      password: ${CP_CONTAINER_REGISTRY_PASSWORD}
    controlPlaneInstanceId: ${CP_INSTANCE_ID}
    #createNetworkPolicy: false    
    serviceAccount: ${CP_INSTANCE_ID}-sa       
    helm:
      url: ${TP_CHART_REGISTRY}
      repo: ${TP_CHART_REPO}
      username: ${TP_CHART_REPO_USER_NAME}
      password: ${TP_CHART_REPO_TOKEN}  
    db_ssl_root_cert_secretname: "${CP_DB_SSL_ROOT_CERT_SECRET_NAME}"
    db_ssl_root_cert_filename: "${CP_DB_SSL_ROOT_CERT_FILENAME}"
  external:
    cpEncryptionSecretName: cporch-encryption-secret
    cpEncryptionSecretKey: CP_ENCRYPTION_SECRET_KEY 
    clusterInfo:
      nodeCIDR: ${CP_NODE_CIDR}
      podCIDR: ${CP_POD_CIDR}
      serviceCIDR: ${CP_SERVICE_CIDR}
    dnsDomain: ${CP_SERVICE_DNS_DOMAIN}
    dnsTunnelDomain: ${CP_TUNNEL_DNS_DOMAIN} 
    db_host: ${CP_DB_HOST}
    db_name: ${CP_DB_NAME}
    db_password: ${CP_DB_PASSWORD}
    db_port: "${CP_DB_PORT}"
    db_secret_name: ${CP_DB_SECRET_NAME}
    db_ssl_mode: ${CP_DB_SSL_MODE}
    db_username: ${CP_DB_USER_NAME}
    emailServerType: smtp    
    emailServer:
      smtp:
        password: "${CP_MAIL_SERVER_PASSWORD}"
        port: "${CP_MAIL_SERVER_PORT_NUMBER}"
        server: ${CP_MAIL_SERVER_ADDRESS}
        username: "${CP_MAIL_SERVER_USERNAME}"
    fromAndReplyToEmailAddress: ${CP_FROM_REPLY_TO_EMAIL}
    adminInitialPassword: ${CP_ADMIN_INITIAL_PASSWORD}    #uncomment to set a intiial password
    admin:
      customerID: ${CP_ADMIN_CUSTOMER_ID}
      email: ${CP_ADMIN_EMAIL}
      firstname: Platform
      lastname: Admin     
tp-cp-configuration:
  tp-cp-subscription:
    resources:
      requests:
       cpu: 100m
       memory: 128Mi
tp-cp-core:
  cronjobs:
    cpcronjobservice:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
    replicaCount: 1
  identity-management:
    idm:
      resources:
        requests:
          cpu: 100m
          memory: 1024Mi
    replicaCount: 1
  identity-provider:
    replicaCount: 1
    tp-cp-identity-provider:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
  orchestrator:
    cporchservice:
      resources:
        requests:
          cpu: 500m
          memory: 256Mi
    replicaCount: 1
  pengine:
    replicaCount: 1
    tpcppengineservice:
      resources:
        requests:
          cpu: 300m
          memory: 128Mi
  user-subscriptions:
    cpusersubservice:
      resources:
        requests:
          cpu: 500m
          memory: 128Mi
    replicaCount: 1
  web-server:
    cpwebserver:
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
    replicaCount: 1
tp-cp-core-finops:
  finops-otel-collector:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
  finops-service:
    finopsservice:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
  finops-web-server:
    finopswebserver:
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
    replicaCount: 1
  monitoring-service:
    monitoringservice:
      resources:
        requests:
          cpu: 100m
          memory: 512Mi
    replicaCount: 1
tp-cp-hawk-recipes:
  enabled: true
tp-cp-hawk:
  enabled: false
  tp-cp-hawk-infra-prometheus:  
    resources:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 2Gi
  tp-cp-hawk-infra-querynode:  
    resources:
      requests:
        cpu: 100m
        memory: 512Mi
      limits:
        cpu: 500m
        memory: 2Gi          
tp-cp-integration:
  enabled: true
  tp-cp-bwce-utilities:
    bwce-utilities:
      bwStudioExtract: true
    enabled: true
  tp-cp-flogo-utilities:
    enabled: true
    flogo-utilities:
        flogoVSCodeExtensionExtract: true  
  tp-cp-integration-bw:
    bw-webserver:
      bwwebserver:
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
    enabled: true
  tp-cp-integration-common:
    fileserver:
      enabled: true
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
  tp-cp-integration-flogo:
    enabled: true
    flogo-webserver:
      flogowebserver:
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
tp-cp-msg-contrib:
  enabled: true
tp-cp-msg-recipes:
  enabled: true  
tp-cp-tibcohub-contrib:
  enabled: true
tp-cp-cli:
  enabled: true
  tpCLIExtract: true
tp-cp-alerts:
  enabled: true
  tp-cp-alertmanager:
    resources:
      requests:
        cpu: 300m
        memory: 256Mi   
  tp-cp-alerts-service:
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
tp-cp-prometheus:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 512Mi                
EOF
  ```

> **_NOTE:_** Ensure  that DNS names for Control Plane Router/UI, and Control Plane Tunnel are mapped to the Ingress Load Balancer IP.



## 13. Update DNS 

On AKS coreDNS should be updated by creating a custom configmap for dns.

``` bash
kubectl apply -f  - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  custom.server: |
    afklm.dataplanes.pro:53 {
      errors
      rewrite name regex (.*)\.afklm\.dataplanes\.pro  haproxy-ingress.ingress-system.svc.cluster.local
      forward . 10.0.0.10 
    }
  log.override: |
    #
  stub.server: |
    #
EOF

``` 

The aim is to rewrite the domainname used for CP to the haproxy server

Update the following:
- afsklm.dataplanes.pro:53 
- rewrite name regex (.*)\.afklm\.dataplanes\.pro  haproxy-ingress.ingress-system.svc.cluster.local

Restart coredns:

``` bash
kubectl rollout restart deployment coredns -n kube-system
```

## 14. Log in CP

Log into the CP with the username / password defined in the above variables (CP_ADMIN_EMAIL and CP_ADMIN_INITIAL_PASSWORD). <br>
First update the cp admin password to a new password <br>


## 15. Create subscription
Create a subscription and check the mailserver to open the activation link.<br>

1) Provision via Editor
2) Update values of userDetails/email  and subscriptionDetails/hostprefix
3) Provision
4) A welcome mail is now sent to the email server with activation link
5) Sign out of the CP UI
5) Open the activation link and add the user details and password.
6) Log into the CP with just created subscription details
7) Goto 'User Management/Users', select the user and assign all permissions to this subscribtion admin user

## 16. Dataplane creation

In the Control Plane UI create a dataplane:

1) 'Data Planes', 'Register a Data Plane', 'Existing Kubernetes Cluster' -> Start <br>

2) 'Basics'<br>add details:
* 'Data Plane Name'
* 'Description' (optional) 
* checkbox the End User Agreement.<br> 
Next

3) 'Namespace and Service Account'<br>
add details:
* 'Namespace' (k8s namespace to be created)
* 'Service Account'(k8s service account to be created)<br>
Next

4) 'Configuration'<br>
In 'Helm Chart Repository section' select Global Repository<br>


5) 'Custom Certificate'. 
This will be created in one of the next steps. The secret name used is 'tp-custom-cert'. <br>
Next

6) Validate the data on the Preview page. <br>Next


After confirming the dataplane configuration four commands need to be executed. For this kubectl and helm access to the cluster is required.


Execute the first two steps:
1) Helm Repository configuration
2) Namespace creation

    After this an additional step needs to be executed to create a secret in the dataplane which contains the custom certificate. 
    For this the environment setting a the top of this document are required.<br>
    In below command validate the value of DATAPLANE_NAMESPACE. This should be the same as the just created Namespace (step 2).

    ``` bash
    export DATAPLANE_NAMESPACE=dp
    kubectl create secret generic tp-custom-cert -n ${DATAPLANE_NAMESPACE} --from-file=${DEFAULT_INGRESS_CERT_FILE}
     ``` 
 3) Service Account creation<br>
 4) Cluster Registration

<br>

 ## 17. Deploy Developer hub capability

 Goto the newly created dataplane.<br>
 'Provision a Capability'<br>
 'Provision TIBCO® Developer Hub', Start<br>

 ### Resources
 'Storage Class'<br>
  Resource name: devhub-storage<br>
  Description :  developer hub storage<br>
  Storage class name: azure-disk-sc<br>

 ### Add Ingress Controller
  Ingress Controller: 'nxinx' (this value is not used anymore in code, hence leave it to nginx)<br>
  Resource name: devhub-ingress<br>
  Ingress Class name: 'haproxy'<br>
  Default FQDN: devhub.dev.benelux.cp1.afklm.dataplanes.pro<br>

##### Ingress Annotations

Add the following ingress annotations to configure the correct use of HA-Proxy.
Please note after adding each annotation the Save button needs to be clicked to store the changes.

| annotation| value|
|-|-|
|haproxy-ingress.github.io/rewrite-target|/|
|haproxy-ingress.github.io/headers| X-Forwarded-Prefix: /tibco/hub<br>X-Forwarded-Host: FQDN<br>X-Forwarded-Port: 443

Where FQDN should be replace by the value as provided in Default FQDN in the Ingress Controller section


### Database resource
  Resource Name:  {name of the database resource}<br>
  Type: PostgreSQL<br>
  Database Host: {full host name of the database server}<br>
  Database Port: {database port>}<br>
  Database Name: {database name>}<br>
  Database Username: {database username of the owner of this database>}<br>
  Database Password: {database password>}<br>

The database (database name) refered to needs to exists and owned by the provided database username.
<br>

### TIBCO® Developer Hub configuration
   Developer Hub Name: provide a name of the developer hub<br>
   Checkbox 'End User Agreement (EUA)'
   Next

### Custom Config

  In order for developer hub to use the postgreSQL database connection with SSL enable a customer configuration is required.
  Create a file 'devhub_custom.yaml' and populate with:

  ``` yaml
  backend:
    database:
      client: pg
      connection:
        database: {database name}
        host: {full host name of the database server}
        port: {database port>}
        user:  {database username of the owner of this database>}
        password: {database password>}
        ssl:
          require: true
          rejectUnauthorized: true

  ```

  Replace the values between the curly brackets and save the file.<br>
  Upload this file as custom configuration.<br>
  Next

### Provisioning

Validate the configured details and click Next to provision the developer hub.



## 18. Post Deployment configuration

Post deployement, nginx specific path regex on Developer Hub ingress must be updated to support haproxy based ingress.

Change to apply to the ingress is

| Before | After|
|-|-|
|path: /tibco/hub/(.*)<br>pathType: ImplementationSpecific|path: /tibco/hub<br>pathType: ImplementationSpecific|


To find the correct ingress use below command

``` bash
kubectl get ingress -n <dp-namespace> | grep tibco-developer-hub
```` 

This will return the name of the ingress.


To edit the ingress use below command

``` bash
kubectl edit ingress -n <dp-namespace> <ingress name>

This will open the default editor (usually vim). Update the mentioned change. 
To save and apply follow the steps:
- press <esc> key
- press colon (:)
- press keys wq

This will update the ingress.

This concludes the setup of developer hub on dataplane with ha-proxy as ingress.