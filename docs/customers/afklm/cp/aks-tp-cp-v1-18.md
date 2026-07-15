# TIBCO Platform Control Plane on AKS

v 1.0 19-nov-2025<br>
v 1.1 10-mrt-2026 upgrade to v1.15 <br>
v 1.2 22-may-2026 upgrade to v1.16 <br>
v 1.3 28-may-2026 upgrade to v1.17 <br>
v 1.4 14-july-2026 upgrade to v1.18 <br>

## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Variables](#environment-variables)
  
- [1. Create Ingress Namespace](#1-create-ingress-namespace)
- [2. Create Default TLS Secret in Ingress namespace](#2-create-default-tls-secret-in-ingress-namespace)
- [3. Install Ingress Controller as a Load Balancer](#3-install-ingress-controller-as-a--load-balancer)
- [4. Install Storage](#4-install-storage)
- [5. Create Control Plane Namespace](#5-create-cp-namespace)
- [6. Create Control Plane Service Account](#6-create-cp-service-account)
- [7. Create Control Plane DB Password Secret](#7-create-cp-db-password-secret)
- [8. Create Control Plane DB TLS Certificate Secret [Optional]](#8-create-cp-db-tls-certificate-secret-optional)
- [9. Create Session Keys Secret](#9-create-session-keys-secret)
- [10. Create Control Plane Encryption Secret](#10-create-cp-encryption-secret)
- [11. Install Platform Base](#11-install-platform-base)
- [12. Install Platform Capabilities](#12-install-platform-capability)
- [13. Update Core DNS](#13-update-dns)
- [14. Log into CP](#14-log-in-cp)
- [14a. Connect to customer Idp](#14-log-in-cp)
- [15. Create Subscription](#15-create-subscription)
- [16. Data plane creation](#16-dataplane-creation)
- [17. Deploy developer hub capability](#17-deploy-developer-hub-capability)
- [18. Developer hub post deployment configuration](#18-post-deployment-configuration)


## Prerequisites
> **_NOTE:_** Documented with TIBCO Platform 1.18.0  
1. Access to AKS K8s cluster
2. Access from the AKS K8S cluster to a PostgreSQL 16.x Database (for instance private end point)
3. Database server parameters to set:<br>
    'require_secure_transport' --> 'OFF' (To change!!!) <br>
    'max_connections' --> 150 <br>
    'azure.extensions' --> 'UUID-OSPP'<br>
3. Access to a SMTP enabled Email Server. 
4. Identify, and register DNS names for Control Plane admin console, subscription, devhub and bwce capabilities  
5. Acquire certificates to secure Control Plane Services. Certificate CN and/or SAN must match Control Plane admin console, subscription, devhub and bwce capabilities.  

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
export DEFAULT_INGRESS_KEY_FILE=private_key.pem ## Full path and filename of Private Key in PEM format
export DEFAULT_INGRESS_CERT_FILE=public_cert.pem ## Full path and filename of Public Key in PEM format
export DEFAULT_INGRESS_TLS_SECRET=ingress-cert-secret ## Default TLS Secret name for Ingress to be created during helm installation

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
export CP_CONTAINER_REGISTRY_USERNAME="image-registry-user" ## TP Image Registry User, TIBCO JFrog Credentials from Control Plane SaaS (to be changed)
export CP_CONTAINER_REGISTRY_PASSWORD="image-registry-password" ## TP Image Registry User, TIBCO JFrog Credentials from Control Plane SaaS (to be changed)
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
export CP_DB_MANAGE_SCHEMA="true" ## If false, DB schema must be manually deployed
export CP_DB_HOST="db.postgres.database.com" ## Control Plane Postgress DB (to be changed)
export CP_DB_PORT="5432" ## Control Plane Postgres DB Port (to be changed)
export CP_DB_SECRET_NAME="cp-db-secret" ## Control Plane DB Secret (to be changed)
export CP_DB_SSL_MODE="disable" # verify-full, disable. Disable is required since DevHub does not support SSL. Azure db server parameter 'require_secure_transport' should be set to 'OFF'
export CP_DB_USER_NAME="db-user" ## Control Plane DB User (to be changed)
export CP_DB_PASSWORD='db-password' ## Control Plane DB Password (to be changed)
export CP_DB_NAME="postgres" ## Control Plane default DB (to be changed)

### Database SSL Config
export CP_DB_SSL_ROOT_CERT_SECRET_NAME="cp-db-ssl" ## Control Plane SSL Secret
export CP_DB_SSL_ROOT_CERT_FILENAME="cp_db_ssl.cert" ## Full path and filename of database ssl certificate (to be changed)
export CP_DB_SSL_ROOT_CERT_FILE="db_ssl.pem" ## Control Plane SSL File name and path in PEM format
```
### Logging 
```bash
export CP_ELASTIC_ENDPOINT="https://dp-config-es-es-http.elastic-system.svc.cluster.local:9200" ## Elasticsearch endpoint for CP Logs, and Audits
export CP_ELASTIC_USER="elastic" ## Elasticsearch User
export CP_ELASTIC_PASSWORD="elasticpassword" ## Elasticsearch Password
export CP_AUDIT_INDEX="tibco-cp-audit" ## CP Audits Index
export CP_LOG_INDEX="tibco-cp-log" ## CP Logs Index
export CP_LOG_ENABLED="false" ## Enable/Disable CP FluentBit
export CP_OTEL_COLLECTOR_ENABLED="true" ## Enable/Disable Otel Collector. Required for Audit Trail and CP logs
```

### Control Plane Bootstrap Config
```bash
### Control Plane Config
export CP_INSTANCE_ID="cp" ## Control Plane Instance ID 
export CP_NAMESPACE="${CP_INSTANCE_ID}-ns" ## Control Plane Namespace
export CP_NODE_CIDR="10.4.0.0/16" ## Node Subnet CIDR (to be changed)
export CP_POD_CIDR="10.4.0.0/20"  ## K8s Pod CIDR (to be changed)
export CP_SERVICE_CIDR="10.0.0.0/16" ## K8s Service CIDR (to be changed)
export TP_BASE_DNS_DOMAIN="azure.airfranceklm.tp" ## TP base domain (to be changed)
export CP_ADMIN_HOST_PREFIX="admin-cp-weu-bwce-cae" ## Customizable Admin host prefix
export CP_SERVICE_DNS_DOMAIN="${TP_BASE_DNS_DOMAIN}" ## Control Plane Router/UI DNS domain 
export CP_TUNNEL_DNS_DOMAIN="${TP_BASE_DNS_DOMAIN}" ## Control Plane Tunnel DNS domain 
export CP_SUBSCRIPTION="dev" ## Control Plane Subscription Name
export CP_STORAGE_PV_SIZE="10Gi" ## Control Plane PV Size
export CP_HYBRID_CONNECTIVITY="true" ## Enable Hybrid Connectivity

```

### Control Plane Base Config
```bash
export CP_PLATFORM_BASE_VERSION=1.18.0 ## Control Plane Base Chart Version
export CP_ADMIN_CUSTOMER_ID="424242" ## Customer ID, available on SaaS CP
export CP_ENABLE_MCP_SERVERS="false" ## Enable MCP Servers
export ENABLE_API_INIT=false ## TRUE to enable API based Admin and CP initialization , e2e automation

## Control Plane bootstrap admin user details
export CP_ADMIN_EMAIL="platform-admin@customer.com" ## Control Plane Admin user used for bootstrap
export CP_ADMIN_INITIAL_PASSWORD="adminpassword" ## Control Plane Admin user for bootstrap Initial Password
```

## Dataplane base Config
``` bash
export DP_NAMESPACE=dp
```

### Adjust for HTTPS/OCI Helm Repo
```bash
if [ "$IS_OCI" = true ] ; then
    HELM_URL="${TP_CHART_REGISTRY}/${TP_CHART_REPO}/"
else
   HELM_URL="--repo ${TP_CHART_REGISTRY}/${TP_CHART_REPO}"
fi
```

## 1. Create Ingress Namespace (when haproxy ingress is not present in the k8s cluster)
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${TP_INGRESS_NAMESPACE}
  labels:
    platform.tibco.com/controlplane-instance-id: ${CP_INSTANCE_ID}
EOF
```

## 2. Create Default TLS Secret in Ingress namespace (when haproxy ingress is not present in the k8s cluster)

```bash
kubectl create secret tls ${DEFAULT_INGRESS_TLS_SECRET} \
    -n  ${TP_INGRESS_NAMESPACE} \
    --key ${DEFAULT_INGRESS_KEY_FILE} \
    --cert ${DEFAULT_INGRESS_CERT_FILE}
```

## 3. Install Ingress Controller as a  Load Balancer (when haproxy ingress is not present in the k8s cluster)

### HAPROXY as Ingress Controller

```bash
helm upgrade --install --wait --timeout 1h --create-namespace  \
  -n  ${TP_INGRESS_NAMESPACE} haproxy-ingress haproxy-ingress \
  --repo "https://haproxy-ingress.github.io/charts" --version 0.14.7 --set controller.service.http.disabled=true -f - <<EOF
controller:
  logs:
    enabled: "true" ## Enable  access logs
  service:
    type: ${TP_INGRESS_SERVICE_TYPE}
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
 kubectl -n ${TP_INGRESS_NAMESPACE} get services haproxy-ingress -o wide 
```
Update DNS entries with this ip address.


### Test HA Proxy Ingress (when haproxy ingress is not present in the k8s cluster) (optional)
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
  ${HELM_URL}dp-config-aks --version "1.18.0" -f - <<EOF
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


## 5. Create Control Plane Namespace
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

## 6. Create Control Plane Service Account
[Reference: Permissions Required by the Role ](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Installation/rbac-permissions.htm)
```bash
kubectl create -n  ${CP_NAMESPACE} serviceaccount ${CP_INSTANCE_ID}-sa
```


## 7. Create Control Plane DB Password Secret
```bash
kubectl apply -f - <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: ${CP_DB_SECRET_NAME}
  namespace: ${CP_NAMESPACE}
  labels:
    app.kubernetes.io/managed-by: Helm
  annotations:
    meta.helm.sh/release-name: tibco-cp-base
    meta.helm.sh/release-namespace: ${CP_NAMESPACE} 
data:
  PASSWORD: $(echo ${CP_DB_PASSWORD} | base64) 
  USERNAME: $(echo ${CP_DB_USER_NAME} | base64)
type: Opaque
EOF
```


## 8. Create Control Plane DB TLS Certificate Secret [Optional only if ssl is enabled]
Required for SSL enabled Databases, where SSL Mode is not set to _disable_
[Reference: Creating K8s Secret for SSL enabled DB](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Installation/creating-secret.htm)
<br>
For creating the certificate please refe to [https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/security-tls#configure-ssl-on-the-client](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/security-tls#configure-ssl-on-the-client)
```bash
kubectl apply -f -  <<EOF
apiVersion: v1
kind: Secret
data:
  ${CP_DB_SSL_ROOT_CERT_FILENAME}: $(cat ${CP_DB_SSL_ROOT_CERT_FILE} | base64 -w 0)
metadata:
  labels:
    app.kubernetes.io/managed-by: "Helm"
  annotations:
    meta.helm.sh/release-name: "tibco-cp-base"
    meta.helm.sh/release-namespace: "${CP_NAMESPACE}"
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

## 10. Create Control Plane Encryption Secret

```bash
kubectl create secret -n ${CP_NAMESPACE} generic cporch-encryption-secret --from-literal=CP_ENCRYPTION_SECRET=$(openssl rand -base64 48 | tr -dc A-Za-z0-9 | head -c44)
```

## 11. Install Platform Base
> **_NOTE:_** Before executing base install, ensure workloads in the cluster can access external resources like Database, Email Server

```bash
helm upgrade --install --wait --timeout 1h --create-namespace  \
  --username ${TP_CHART_REPO_USER_NAME} --password ${TP_CHART_REPO_TOKEN} \
  -n ${CP_NAMESPACE}  tibco-cp-base  ${HELM_URL} tibco-cp-base  \
  --version "${CP_PLATFORM_BASE_VERSION}" -f - <<EOF
global:
  tibco:
    adminHostPrefix: ${CP_ADMIN_HOST_PREFIX}
    serviceAccount: ${CP_INSTANCE_ID}-sa         
    manageDbSchema: ${CP_DB_MANAGE_SCHEMA}              
    containerRegistry:
      url: ${CP_CONTAINER_REGISTRY}
      repository: ${CP_CONTAINER_REGISTRY_REPOSITORY}      
      username: ${CP_CONTAINER_REGISTRY_USERNAME}    
      password: ${CP_CONTAINER_REGISTRY_PASSWORD}
    hybridConnectivity:
      enabled: ${CP_HYBRID_CONNECTIVITY}
    controlPlaneInstanceId: ${CP_INSTANCE_ID}           
    useSingleNamespace: true ## force setting to address a msg-webserver issue        
    logging:
      fluentbit:
        enabled: ${CP_LOG_ENABLED}  ## Disabling fluentbit, but logserver eanbled for auditrail
    ## For SSL enabled DB
    db_ssl_root_cert_secretname: "${CP_DB_SSL_ROOT_CERT_SECRET_NAME}"
    db_ssl_root_cert_filename: "${CP_DB_SSL_ROOT_CERT_FILENAME}"        
  external:   
    db_host: ${CP_DB_HOST}
    db_name: ${CP_DB_NAME}    
    db_port: "${CP_DB_PORT}"    
    db_username: ${CP_DB_USER_NAME}
    db_password: ${CP_DB_PASSWORD}
    db_secret_name: ${CP_DB_SECRET_NAME}
    db_ssl_mode: ${CP_DB_SSL_MODE}
    cpEncryptionSecretKey: CP_ENCRYPTION_SECRET      
    cpEncryptionSecretName: cporch-encryption-secret
    enable_api_based_initialization: ${ENABLE_API_INIT}
    emailServerType: smtp    
    emailServer:
      smtp:
        password: "${CP_MAIL_SERVER_PASSWORD}"
        port: "${CP_MAIL_SERVER_PORT_NUMBER}"
        server: ${CP_MAIL_SERVER_ADDRESS}
        username: "${CP_MAIL_SERVER_USERNAME}"
    fromAndReplyToEmailAddress: ${CP_FROM_REPLY_TO_EMAIL} 
    cronJobReportsEmailAlias: ${CP_JOB_REPORT_TO_EMAIL}
    platformEmailNotificationCcAddresses: ${CP_NOTIFICATION_CC_EMAIL}
      
    adminInitialPassword: ${CP_ADMIN_INITIAL_PASSWORD}    
    admin:
      customerID: ${CP_ADMIN_CUSTOMER_ID}
      email: ${CP_ADMIN_EMAIL}
      firstname: Platform
      lastname: Admin
    dnsDomain: ${TP_BASE_DNS_DOMAIN}
    dnsTunnelDomain: ${TP_BASE_DNS_DOMAIN}  ## Required when hybridConnectivity.enabled=true                      
    clusterInfo:
      nodeCIDR: ${CP_NODE_CIDR}
      podCIDR: ${CP_POD_CIDR}
      serviceCIDR: ${CP_SERVICE_CIDR}      
    auditserver: ## Required for Audit Trails
      index: ${CP_AUDIT_INDEX}    
    logserver: ## Required for Audit Trails
      endpoint: ${CP_ELASTIC_ENDPOINT}
      index: ${CP_LOG_INDEX}
      password: ${CP_ELASTIC_PASSWORD}
      username: ${CP_ELASTIC_USER}    
    storage:
      resources:
        requests:
          storage: ${CP_STORAGE_PV_SIZE}
      storageClassName: ${RWX_STORAGE_CLASS}     
otel-collector:
  enabled: ${CP_OTEL_COLLECTOR_ENABLED}
router-operator:
  ingress:
    enabled: true
    annotations: ## enable annotations for nginx-ingress and haproxy-ingress
      haproxy-ingress.github.io/headers: "X-Forwarded-Port: 443" # for haproxy-ingress: default ingress https-port
    ingressClassName: ${TP_INGRESS_CLASS}   
    hosts:
      - host: "${CP_SUBSCRIPTION}.${TP_BASE_DNS_DOMAIN}"
        paths:
          - path: /
            pathType: Prefix
            port: 100            
      - host: "${CP_ADMIN_HOST_PREFIX}.${TP_BASE_DNS_DOMAIN}"
        paths:
          - path: /
            pathType: Prefix
            port: 100
hybrid-proxy:  ## Required when hybridConnectivity.enabled=true
  ingress:
    enabled: true
    annotations: ## enable annotations for nginx-ingress and haproxy-ingress
      haproxy-ingress.github.io/headers: "X-Forwarded-Port: 443" # for haproxy-ingress: default ingress https-port
    ingressClassName: ${TP_INGRESS_CLASS}         
    hosts:
      - host: '${CP_SUBSCRIPTION}.${TP_BASE_DNS_DOMAIN}'                                        
tp-cp-prometheus:
  server:
    resources:
      requests:
        cpu: 100m
        memory: 512Mi
############
## BW Charts
############
bw-webserver:
  bwwebserver:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
  ##MCP Server
  bwmcpserver:
    enabled: ${CP_ENABLE_MCP_SERVERS}
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
bwce-utilities:
  enabled: true
bw5ce-utilities:
  enabled: true
############
## Flogo Charts
############
flogo-webserver:
  flogowebserver:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
  ##MCP Server
  mcpserver:
    enabled: ${CP_ENABLE_MCP_SERVERS}
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
flogo-utilities:
  enabled: true
flogo-recipes:
  enabled: true
############  
## DevHHub Charts               
############
tibcohub-recipes:
  enabled: true
tibcohub-contrib:
  enabled: true
############  
##Messaging Charts  
############
resources:
  requests:
    cpu: 100m
    memory: 128Mi
############    
## Hawk Charts      
############
# Add to customize hawkconsole recipe
# recipeOverride:
#   HAWKCONSOLE:
#     hawkconsole:
#       javaOptions: "-Xms1g -Xmx4g"
tp-cp-hawk-infra-querynode:  
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
EOF
  ```

> **_NOTE:_** Ensure  that DNS names for Control Plane Router/UI, and Control Plane Tunnel are mapped to the Ingress Load Balancer IP.



## 12. Update DNS 

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
    azure.airfranceklm.com:53 {
      errors
      rewrite name regex (.*)\.azure\.airfranceklm\.tp  haproxy-ingress.ingress-system.svc.cluster.local
      forward . 10.0.0.10 
    }
  log.override: |
    #
  stub.server: |
    #
EOF

``` 

The aim is to rewrite the domainname used for Control Plane to the haproxy server

Update the following (if dns names are changing):
- azure.airfranceklm.com:53 
- rewrite name regex (.*)\.azure\.airfranceklm\.com  haproxy-ingress.ingress-system.svc.cluster.local

Restart coredns:

``` bash
kubectl rollout restart deployment coredns -n kube-system
```

## 12. Install Platform Capability

Starting 1.13.0 Platform capabilities are decoupled, and are installed separately. 

Capability charts reuse the Platform base (tibco-cp-base) chart configurations, and support capability specific customization. Get values from the deployed Platform base to reuse 

```bash
export CP_VALUES_FILE=aks-tibco-cp-base-1.17.0.yaml
helm get values -n $CP_NAMESPACE tibco-cp-base  > $CP_VALUES_FILE
```

### Install BW Capability

```bash

helm upgrade --install -n $CP_NAMESPACE tibco-cp-bw ${HELM_URL} tibco-cp-bw -f $CP_VALUES_FILE --set bw5ce-utilities.bw5CleanupJob=true --set bwce-utilities.bwCleanupJob=true --set bw-recipes.recipeCleanupJob=true --version=${CP_PLATFORM_BASE_VERSION}
```

### Install Flogo Capability

```bash
helm upgrade --install -n $CP_NAMESPACE tibco-cp-flogo ${HELM_URL} tibco-cp-flogo -f $CP_VALUES_FILE --set flogo-utilities.cleanupJob=true --set flogo-recipes.cleanupJob=true --version=${CP_PLATFORM_BASE_VERSION}
```

### Install DevHub Capability

```bash
helm upgrade --install -n $CP_NAMESPACE tibco-cp-devhub ${HELM_URL} tibco-cp-devhub -f $CP_VALUES_FILE --version=${CP_PLATFORM_BASE_VERSION}
```

### Install Messaging Capability

```bash
helm upgrade --install -n  $CP_NAMESPACE tibco-cp-messaging ${HELM_URL} tibco-cp-messaging -f $CP_VALUES_FILE --version='1.15.*'
```

please note version is different from cp version.

### Install Hawk Capability

```bash
helm upgrade --install -n  $CP_NAMESPACE tibco-cp-hawk  ${HELM_URL} tibco-cp-hawk -f $CP_VALUES_FILE  --version='1.18.*'
```


## 13. Log in CP

Log into the Control Plane with the username / password defined in the above variables (CP_ADMIN_EMAIL and CP_ADMIN_INITIAL_PASSWORD). <br>
First update the Control Plane admin password to a new password <br>


## 14. Configure Email server

Configure the email server connection.
1) Click Email Server Configuration''
2) Select the appropiate 'Email Service Type"
3) Fill out the required details related to the 'Email Service Type'
4) Confirm and store by clicking 'Save'



## 15. Create subscription
Create a subscription and check the mailserver to open the activation link.<br>

1) Click 'Subscriptions'
2) Click 'Provision via Editor'
3) Update values of userDetails/email  and subscriptionDetails/hostprefix
4) Click 'Provision'

welcome mail is now sent to the email server with activation link

5) Sign out of the Control Plane UI
5) Open the activation link and add the user details and password.
6) Log into the Control Plane with just created subscription details
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
    export DATAPLANE_NAMESPACE=${DP_NAMESPACE}
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
  Select Database resource
  Add Database Resource
  Resource name: devhub-storage<br>
  Database Host: {full host name of the database server}<br>
  Database Port: {database port>}<br>
  Database Name: {database name>}<br>
  Database Username: {database username of the owner of this database>}<br>
  Database Password: {database password>}<br>

  These database details should refer to a postgres dba user and main database (default: postgres)
  
 ### Add Ingress Controller
  Ingress Controller: 'nxinx' (this value is not used anymore in code, hence leave it to nginx)<br>
  Resource name: devhub-ingress<br>
  Ingress Class name: 'haproxy'<br>
  Default FQDN: devhub-weu-bwce-cae.azure.airfranceklm.tp<br>

##### Ingress Annotations

Add the following ingress annotations to configure the correct use of HA-Proxy.
Please note after adding each annotation the Save button needs to be clicked to store the changes.

| annotation| value|
|-|-|
|haproxy-ingress.github.io/rewrite-target|/|
|haproxy-ingress.github.io/headers| X-Forwarded-Prefix: /tibco/hub<br>X-Forwarded-Host: FQDN<br>X-Forwarded-Port: 443

Where FQDN should be replace by the value as provided in Default FQDN in the Ingress Controller section



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