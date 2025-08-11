# Setting up a Control Tower Data Plane with a Single-Cluster Kubernetes Cluster on MicroK8s

(origin: https://github.com/TIBCOSoftware/tp-helm-charts/blob/main/docs/workshop/microk8s/bare-metal-data-plane/README.md)
> updated for minikube based installation.

This workshop guides you through setting up a single-cluster Kubernetes cluster on Minikube in preparation for provisioning a Control Tower Data Plane on TIBCO Platform. We will create a single Minikube cluster on your machine with host storage for persistence and provision Observability backend servers for collecting OpenTelemetry data including Prometheus and ElasticSearch if not already available or configured. It provisions a Nginx ingress controller in preparation for receiving incoming requests from non-Kubernetes workloads such as metrics and traces from BusinessWorks User Apps running outside the Kubernetes cluster. It also also allows you to monitor and manage EMS servers running outside the Kuberbetes cluster.

---
## Prerequisites for a Control Tower Data Plane on TIBCO Platform
- Host operating system
   - Linux
- Minimum hardware requirements 
   - CPU: 4-core Processor
   - Memory: 8 GB RAM
   - Storage: 20 GB disk space
   - CPU architecture: x86_64
- Nginx Ingress Controller 
   - Inbound OpenTelemetry data and TEA agent leader election
- Host Storage Class
   - Persistence for HawkConsole
- Observability backend resources for collecting OpenTelemetry data for BusinessWorks applications
   - Metrics collection
      - Prometheus
   - Traces collection
      - ElasticSearch

This **`readme`** covers the prerequisites to get you started with a single-cluster Kubernetes cluster on Minikube. Follow each step carefully to ensure a smooth setup process before provisioning a Control Tower Data Plane on TIBCO Platform.

---

## Steps
1. [Installation of MicroK8s](#installation-of-microk8s)
2. [Setting Up Storage Class](#setting-up-storage-class)
3. [Install Nginx Ingress Controller](#install-nginx-ingress-controller)
4. [Install Prometheus for Metrics](#install-prometheus-for-metrics)
5. [Install ElasticSearch for Traces](#install-elasticsearch-for-traces)
6. [Create ElasticSearch Index Template for Traces](#create-elasticsearch-index-template-for-traces)

---

## Installation of MicroK8s

> [!NOTE]
>
> 
1. **Install Minikube**

   ### Linux
      
      Refer to the platform deployment guide for installing minikube [Prepare platform deployment minikube](docs/baseplatforms/prepare-platform-deployment-minikube.md)
      
    
---

## Setting Up minikube addons

In preparation for the Control Tower Data Plane on TIBCO Platform, it is required to create a storage class for persistence and ingress. For Minikube, you can enable the storage-provisioner addon for persistence on the your host system. For ingress the ingress addon can be used.


1. Check status of the Minikube storage addon:
   ```bash
   minikube addons list 
   ```

This will prove a list with all the addons and their status.
Addon 'storage-provider' and 'ingress' should be 'enabled'. 
If not enabled execute the command to enable it.

2. Enable storage-provider addon:

```
minikube addons enable storage-provisioner
minikube addons list
```

The addon should now be enabled

3. Verify the default storage class in the minikube cluster:

   ```
   $ kubectl get storageclass
   ```

   ```
   NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
   standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  9d
   ```

> [!NOTE]
> Please note down the name of the storage class name **`standard`** (example above), you will need this during the provisioning wizard of the Control Tower Data Plane on TIBCO Platform.


```
## Install Nginx Ingress Controller

The Control Tower Data Plane on TIBCO Platform requires an Ingress Controller to route all incoming requests to the corresponding TIBCO service components running in the Minikube cluster.

The incoming requests include:
- OpenTelemtry data like traces and metrics from BW5 applications
- TEA Agent leader election notification for BW6 applications

In current release, Control Tower Data Plane supports the Nginx Ingress Controller.


1. Add the Helm repository and update:
   
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   ```

2. Install the Nginx ingress controller with a fixed class name on its own namespace:

    For DATAPLANE_NAME use the exact same name as how the database is going to be registered in the control plane.
    <br>For MACHINE_IP use the ip address the minikube container is running at. This can be retreived by the command

    ```
    minikube ip
    ```
   
    ```bash
   DATAPLANE_NAME=<dpname>
   MACHINE_IP=<your-machine-private-ip>
   INGRESS_NS=ingress
   INGRESS_CLASS_NAME=${DATAPLANE_NAME}-nginx-ingress
   helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --set controller.ingressClassResource.name=${INGRESS_CLASS_NAME} --set "controller.service.externalIPs[0]=${MACHINE_IP}" --namespace ${INGRESS_NS} --create-namespace
   ```

3. Validate your ingress class

      ```
      $ kubectl get ingressclass
      NAME                CONTROLLER             PARAMETERS   AGE
      <dpname>-nginx-ingress   k8s.io/ingress-nginx   <none>       26s
      ```

> [!NOTE]
>
> - Please note down the name of the Ingress Controller class name **`<dpname>-nginx-ingress`** (example above), you will need this during the provisioning wizard of the Control Tower Data Plane on TIBCO Platform
> - Make sure a host name is assigned to the **`MACHINE_IP`** or create a DNS record for the IP, you will need the host name to set as the **`FQDN`** name during the provisioning wizard of the Control Tower Data Plane on TIBCO Platform

---
<br>

## Install the Control Tower data plane

At this point the control tower data plane needs to be created.
In the TIBCO Platform Control Plane select the Data planes view and start the 'Register Data Plane' wizard.

Select the 'Control Tower' option
```
>> Data Plane Details

Fill out the Data plane details. It is advisable to use all lower case characters for the 'Data Plane Name' since this name is also used to create an ingress controller name. Only lower case characters are allowed for the ingress controller name.

For Machine Host name use the FQDN of the (host) machine the control plane (=minikube) is running on. 

Once all the mandetory fields are entered click 'Procees with Advanced Configuration'.
This is required since with minikube the storage class name is different than the one for the Basic installation.
```

```
>> Namespace & Service account

Adjust namespace and service account names, or use the defaults.

Click Next
```

```
>> Storage Class

Change content of field 'Storage Class Name' to 'standard'. 
For all other fields the standard values can be used, or changed to specific requirements.

Click Next
```
```
>> Configuration
Settings for Proxy, Container Registration and and Helm Chart Repository can be accecpts as proposed, or change to specific requirements.

Click Next
```

```
>> Preview
Validate the overview of configurations and Edit if required.

Click 'Register on Control Plane now' 
```

Now select 'Display Details & Registration Commands' to view the four commands to deploy the control tower dataplane to the minikube cluster.
Execute these command sequentially and after some time the Control Tower Data Plane will become visable and in green status on the Data Plane page.

---



## Install ElasticSearch for Traces

> [!NOTE]
>
> If the Control Tower Data Plane is used only for monitor and manage EMS servers, installing _ElasticSearch for Traces_ is not required. You can skip this section.

For Observability of traces on the Control Tower Data Plane on TIBCO Platform, it is required to have a ElasticSearch server configured to collect the traces. 

If you do not have an existing ElasticSearch server server already installed in your Organization, the following steps guide you through the installation of ElastServer server inside the MicroK8s cluster.

1. Add the Helm repository and update:

   ```bash
   helm repo add elastic https://helm.elastic.co
   helm repo update
   ```

2. Install ElasticSearch using Helm:

   - Use the following helm command with the default microk8s host storage class name as the persistence

      ``` bash
      ES_NS=elastic
      ES_STORAGE_CLASS=standard
      ES_STORAGE_SIZE=10G
      helm upgrade --install elasticsearch elastic/elasticsearch --set persistence.enabled=true,replicas=1 --set volumeClaimTemplate.storageClassName=${ES_STORAGE_CLASS},volumeClaimTemplate.resources.requests.storage=${ES_STORAGE_SIZE} -n ${ES_NS} --create-namespace
      ```

   - Apply ingress [elastic_ingress.yaml](./elasticsearch_ingress.yaml) to ensure the `ingressClassName`, `namespace` and `host` are set proper accordingly
      - The ingress for ElasticSearch allows allows other Control Tower Data Planes running outside the cluster to query

      ```bash
      ES_INGRESS_FILE=elasticsearch_ingress.yaml
      kubectl apply -f ${ES_INGRESS_FILE}
      ```
   
   - Check the ElasticSearch connectivity with the following:
   
      ```bash
      MACHINE_HOST=<your_machine_host>
      ES_PASSWORD=$(kubectl get secrets -n elastic elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
      curl -k -u elastic:${ES_PASSWORD} http://${MACHINE_HOST}/o11y/traces-server
      ```

      - Sample output

         ```
         $ MACHINE_HOST=gasdbwbw5ct01.dev.tibco.com
         $ ES_PASSWORD=$(kubectl get secrets -n elastic elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
         $ curl -k -u elastic:${ES_PASSWORD} https://${MACHINE_HOST}/o11y/traces-server
         {
         "name" : "elasticsearch-master-0",
         "cluster_name" : "elasticsearch",
         "cluster_uuid" : "YSsKREB1TpWU7ZRustlqaA",
         "version" : {
            "number" : "8.5.1",
            "build_flavor" : "default",
            "build_type" : "docker",
            "build_hash" : "c1310c45fc534583afe2c1c03046491efba2bba2",
            "build_date" : "2022-11-09T21:02:20.169855900Z",
            "build_snapshot" : false,
            "lucene_version" : "9.4.1",
            "minimum_wire_compatibility_version" : "7.17.0",
            "minimum_index_compatibility_version" : "7.0.0"
         },
         "tagline" : "You Know, for Search"
         }

         ```

>>>[!NOTE]
Since minikube is running inside a docker container the machine-name may not resolve properly.
In order to pass the correct machine name to pass in the command for ingress to perform the proper routing we can force the curl command to resolve that machine name to the ip address the minikube container is running at.

```
MACHINE_HOST=<your_machine_host>
MINI_IP=$(minikube ip)
ES_PASSWORD=$(kubectl get secrets -n elastic elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
curl -k -u elastic:${ES_PASSWORD} https://${MACHINE_HOST}/o11y/traces-server  --resolve ${MACHINE_HOST}:443:${MINI_IP}
```



> [!NOTE]
>
> #### For ElasticSearch running inside the cluster
> - Note down the URL **`https://elasticsearch-master.elastic.svc:9200`** when you configure the traces server of Observability resource in TIBCO Platform
>

> #### User name and password
> - The username is `elastic` and you can obtain the password as below:
>   ```bash
>   ES_PASSWORD=$(kubectl get secrets -n elastic elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d) && echo $ES_PASSWORD
>   ```

> [!NOTE]
>
> - You can [install another minkube ](#installation-of-microk8s) cluster on a delegated machine separately to host both the Prometheus and ElasticSearch servers for collectiing Observability data. Following the same `helm` install step for ElasticSearch so multiple Control Tower Data Planes can use the same Observability backend servers as Global Observability resource in TIBCO Platform
> - Note down the URL `http://<machine-host_name>/o11y/traces-server` when you configure the traces server of Observability resource in TIBCO Platform

---

## Create ElasticSearch Index Template for Traces

> [!NOTE]
>
> If the Control Tower Data Plane is used only for monitor and manage EMS servers, _ElastiSearch Index Template for Traces_ is not required. You can skip this section.

The following files are required to set up the ElasticSearch index before collecting OpenTelemetry OTLP traces

   * [Trace Service index template for Jaeger](./jaeger_service_index_template.json): `jaeger_service_index_template.json`
   * [Trace Span index template for Jaeger ](./jaeger_span_index_template.json): `jaeger_span_index_template.json`
   * [Trace Index Lifecycle Policy](./jaeger_index_policy.json): `jaeger_index_policy.json`
   * [Trace Service rollover index](./jaeger_service_rollover_index.json) `jaeger_service_rollover_index.json`
   * [Trace Span rollover index](./jaeger_span_rollover_index.json) `jaeger_span_rollover_index.json`

> [!NOTE]
>
> Make sure you download the above required files to your local directory before executing the following command to create the index templates.
Use the --resolve ${MACHINE_HOST}:443:${MINI_IP} if required as described above.

#### Execute the following commands to create the index templates for traces
   ```bash
   MACHINE_HOST=<your-machine-private-host-name>
   ES_PASSWORD=$(kubectl get secrets -n elastic elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d)
   #
   JAEGER_INDEX_POLICY=jaeger_index_policy.json
   curl -k -X PUT -H 'Content-Type: application/json' -u elastic:${ES_PASSWORD} -d@${JAEGER_INDEX_POLICY} https://${MACHINE_HOST}/o11y/traces-server/_ilm/policy/jaeger-index-policy
   #
   JAEGER_SERVICE_ROLLOVER_INDEX=jaeger_service_rollover_index.json
   curl -k -X PUT -H 'Content-Type: application/json' -u elastic:${ES_PASSWORD} -d@${JAEGER_SERVICE_ROLLOVER_INDEX} https://${MACHINE_HOST}/o11y/traces-server/jaeger-service-000001
   #
   JAEGER_SERVICE_INDEX_TEMPLATE=jaeger_service_index_template.json
   curl -k -X PUT -H 'Content-Type: application/json' -u elastic:${ES_PASSWORD} -d@${JAEGER_SERVICE_INDEX_TEMPLATE} https://${MACHINE_HOST}/o11y/traces-server/_index_template/jaeger_service
   #
   JAEGER_SPAN_ROLLOVER_INDEX=jaeger_span_rollover_index.json
   curl -k -X PUT -H 'Content-Type: application/json' -u elastic:${ES_PASSWORD} -d@${JAEGER_SPAN_ROLLOVER_INDEX} https://${MACHINE_HOST}/o11y/traces-server/jaeger-span-000001
   #
   JAEGER_SPAN_INDEX_TEMPLATE=jaeger_span_index_template.json
   curl -k -X PUT -H 'Content-Type: application/json' -u elastic:${ES_PASSWORD} -d@${JAEGER_SPAN_INDEX_TEMPLATE} https://${MACHINE_HOST}/o11y/traces-server/_index_template/jaeger_span
   ```

   - Validate the index template are created

      ```bash
      curl -k -u elastic:${ES_PASSWORD} https://${MACHINE_HOST}/o11y/traces-server/_index_template/jaeger_service | jq .
      curl -k -u elastic:${ES_PASSWORD} https://${MACHINE_HOST}/o11y/traces-server/_index_template/jaeger_span | jq .
      ```

---
REMAING INSTRUCTION ARE NOT REQUIRED !!!!

## Install Prometheus for Metrics

> [!NOTE]
>
> Out of the box the Control Plan Prometheus instance can be used to scrape the metrices from the Control tower. No direct need to install Prometheus on the control tower dataplane

For Observability of metrics on the Control Tower Data Plane on TIBCO Platform for BusinessWorks applications, it is required to have a Prometheus server configured to collect the metrics. 

If you do not have an existing Prometheus server already installed in your Organization, the following steps guide you through the installation of Prometheus server inside the MicroK8s cluster. It installs Prometheus and add the following [kuberbetes otel-collector scrape configurations](./prometheus_scrape_k8s_sd_config.yaml). The Prometheus scrape configuration contains the `otel-collector` job that discovers and collects metrics from the OpenTelemetry servics of TIBCO Platform service running inside the MicroK8s cluster.

Alternatively, you can also install Prometheus on another machine that allows you to scrape metrics from multiple Control Tower Data Planes with a [static otel-collector scrape configuration](./prometheus_scrape_static_config.yaml). Follow the steps hightlighted below.

1. Add the Helm repository and update:

   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo update
   ```

2. Install Prometheus using Helm:

   #### To install Prometheus **`inside`** the Control Tower Data Plane cluster
   
   - Use the [prometheus_scrape_k8s_sd_config.yaml](prometheus_scrape_k8s_sd_config.yaml) scrape configuration to collect the exported metrics from inside the cluster

      ```bash
      PROM_NS=prometheus
      RETENTION_POLICY=7d
      SCRAPE_CONFIG_FILE=prometheus_scrape_k8s_sd_config.yaml
      helm upgrade --install prometheus prometheus-community/prometheus --set server.retention=${RETENTION_POLICY} --namespace ${PROM_NS} --create-namespace -f ${SCRAPE_CONFIG_FILE}
      ```
   - Check the connectivity with the following:

      ```bash
      PROM_POD=$(kubectl get pods -n prometheus | grep prometheus-server | awk '{print $1;}')
      kubectl exec -it $PROM_POD -n prometheus -c prometheus-server -- sh -c 'wget -O - prometheus-server/version'
      ```

      - Sample output

         ```
         $ PROM_POD=$(kubectl get pods -n prometheus | grep prometheus-server | awk '{print $1;}')
         $ kubectl exec -it $PROM_POD -n prometheus -c prometheus-server -- sh -c 'wget -O - prometheus-server/version'
         Connecting to prometheus-server (10.152.183.173:80)
         writing to stdout
         {"version":"2.52.0","revision":"879d80922a227c37df502e7315fad8ceb10a986d","branch":"HEAD","buildUser":"root@1b4f4c206e41","buildDate":"20240508-21:56:43","goVersion":"go1.22.3"}
         ```

   #### To install Prometheus **`outside`** the Control Tower Data Plane on another cluster

   - Use the [prometheus_scrape_static_config.yaml](./prometheus_scrape_static_config.yaml) scrape configuration to collect exported metrics from each cluster

      ```bash
      PROM_NS=prometheus
      RETENTION_POLICY=7d
      SCRAPE_CONFIG_FILE=prometheus_scrape_static_config.yaml
      helm upgrade --install prometheus prometheus-community/prometheus --set server.retention=${RETENTION_POLICY} --namespace ${PROM_NS} --create-namespace -f ${SCRAPE_CONFIG_FILE}
      ```

   - [Install Nginx Ingress Controller](#install-nginx-ingress-controller) for exposing metrics query service of target Control Tower Data Plane
      - Apply ingress [prometheus_ingress.yaml](./prometheus_ingress.yaml) to ensure the `ingressClassName`, `namespace` and `host` are set proper accordingly
         - The ingress for Prometheus allows allows other Control Tower Data Planes running outside the cluster to query

         ```bash
         PROM_INGRESS_FILE=prometheus_ingress.yaml
         kubectl apply -f ${PROM_INGRESS_FILE}
         ```

   - Check the connectivity with the following:

      ```bash
      MACHINE_HOST=<your-machine-private-host-name>
      curl ${MACHINE_HOST}/o11y/metrics-server/version
      ```

      - Sample output:

         ```
         $ MACHINE_HOST=gasdbwbw5ct01.dev.tibco.com
         $ curl $MACHINE_HOST/o11y/metrics-server/version
         {"version":"2.52.0","revision":"879d80922a227c37df502e7315fad8ceb10a986d","branch":"HEAD","buildUser":"root@1b4f4c206e41","buildDate":"20240508-21:56:43","goVersion":"go1.22.3"}
         ```

> [!NOTE]
>
> #### For Prometheus running inside the cluster
> - Note down the URL **`http://prometheus-server.prometheus.svc`** when you configure the metrics server of Observability resource in TIBCO Platform
> 
> #### For Prometheus running outside the cluster
> - Note down the URL **`http://<your_machine_host>/o11y/metrics-server`** when you configure the metrics server of Observability resource in TIBCO Platform

> [!NOTE]
>
> You can [install another Minikube](#installation-of-microk8s) cluster on a delegated machine separately to host both the Prometheus and ElasticSearch servers for collectiing Observability data. Following the same `helm` install step for Prometheus so multiple Control Tower Data Planes can use the same Observability backend servers as Global Observability resource in TIBCO Platform

> [!IMPORTANT]
>
>  - You need to substitute the `%%data_plane_id%%` and `%%host_name_fqdn%%` in [prometheus_scrape_static_config.yaml](./prometheus_scrape_static_config.yaml)
>  - Multiple scrape job targets `otel-metrics_%%dataplane_id%%` can be combined in the same static config yaml file
>  - To reload the static scrape config with new Control Tower Data Plane targets, rerun the `helm upgrade --install` command for Prometheus
>     - This will not disrupt the existing metrics data in persistence
---