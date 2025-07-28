
**Note:** This documentation is expanded and created from a base reference documentation as desribed here: [tp-helm-charts/Install and configure observability](https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/docs/workshop/aro%20(Azure%20Red%20Hat%20OpenShift)/data-plane#install--configure-observability-tools)



# How to Install Elastic ECK and Prometheus on OpenShift ARO for Data Plane Observability

This guide provides step-by-step instructions to install [Elastic ECK (Elastic Cloud on Kubernetes)](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-installation.html) and configure Prometheus on OpenShift Azure Red Hat OpenShift (ARO).

---

## Prerequisites

* Access to an OpenShift ARO cluster.
* `oc` or `kubectl` CLI installed and configured.
* Cluster admin privileges (`system:admin` or equivalent user with privileges to create Projects, CRDs, and RBAC resources at the cluster level).

---

## 1. Install Elastic ECK Operator

### 1.1. Initial Setup

**Set Virtual Memory Settings:**

Before deploying an Elasticsearch cluster, ensure Kubernetes nodes have the correct `vm.max_map_count` sysctl setting. ECK-created Pods typically run with the restricted Security Context Constraint (SCC), which prevents changing this setting. This is a common requirement for Elasticsearch.

Alternatively, set `node.store.allow_mmap: false` in the Elasticsearch node configuration. This has performance implications and is **not recommended for production workloads**.

For more details, refer to the [Elasticsearch Virtual memory documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html) and [ECK on OpenShift considerations](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html#k8s-openshift-virtual-memory).

### 1.2. Deploy the ECK Operator

Apply the manifests as described in the [Install ECK using the YAML manifests](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart-self-managed.html) document:

```sh
oc create -f https://download.elastic.co/downloads/eck/2.16.0/crds.yaml
oc apply -f https://download.elastic.co/downloads/eck/2.16.0/operator.yaml
```

### 1.3. Network Configuration (Optional)

If your Software Defined Network (SDN) uses the `ovs-multitenant` plug-in, allow the `elastic-system` namespace to access other Pods and Services. This is specific to certain OpenShift network configurations. See [ECK on OpenShift networking](https://www.google.com/search?q=https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html%23k8s-openshift-networking).

```sh
oc adm pod-network make-projects-global elastic-system
```

### 1.4. Create a Project for Elastic Resources

Create a dedicated namespace for Elastic resources (Elasticsearch, Kibana, APM Server, etc.). A non-default namespace is required for automatic application of default Security Context Constraint (SCC) permissions, as detailed in [ECK on OpenShift prerequisites](https://www.google.com/search?q=https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html%23k8s-openshift-prerequisites).

```sh
oc new-project elastic
```

This command will create the `elastic` project and switch to it.

### 1.5. Grant User Permissions (Optional)

To allow another user or group to manage Elastic resources in the `elastic` namespace:

```sh
# Example: Allow 'developer' user to manage Elastic resources in the 'elastic' namespace
oc adm policy add-role-to-user elastic-operator developer -n elastic
```

### 1.6. Deploy Elasticsearch Cluster

Create an Elasticsearch cluster (`elasticsearch-sample`) with a "passthrough" route:

**Note:** Ensure this is deployed in a non-default namespace (e.g., `elastic`).

```yaml
cat <<EOF | oc apply -n elastic -f -
# This sample sets up an Elasticsearch cluster with an OpenShift route
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch-sample
spec:
  version: 8.17.3 # Specify your desired Elasticsearch version
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false # Not recommended for production, see virtual memory notes
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: elasticsearch-sample
spec:
  #host: elasticsearch.example.com # Override if you don't want the auto-generated host
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: elasticsearch-sample-es-http
EOF
```

  * Elasticsearch serves as the TLS endpoint.
  * For **Elasticsearch plugins**: Plugins usually cannot be installed at runtime in OpenShift due to root privilege restrictions. Use custom images as described in [Create custom images with ECK](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-custom-images.html).

### 1.7. Deploy Kibana Instance

Create a Kibana instance (`kibana-sample`) with a "passthrough" route:

```yaml
cat <<EOF | oc apply -n elastic -f -
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana-sample
spec:
  version: 8.17.3 # Match your Elasticsearch version
  count: 1
  elasticsearchRef:
    name: "elasticsearch-sample"
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          limits:
            memory: 1Gi
            cpu: 1
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: kibana-sample
spec:
  #host: kibana.example.com # Override if you don't want the auto-generated host
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: kibana-sample-kb-http
EOF
```

  * Kibana serves as the TLS endpoint.

To get the hosts for Elasticsearch and Kibana Routes:

```sh
oc get route -n elastic
```

### 1.8. Deploy APM Server

**Note:** Enterprise Search is not available in versions 9.0+.

For APM Server versions older than 7.9, a workaround is needed to run with the restricted SCC by assigning it to the `anyuid` SCC. Starting with version 7.9, APM Server can run with the restricted SCC. See [ECK on OpenShift Security Context Constraints](https://www.google.com/search?q=https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html%23k8s-openshift-scc).

**Create a Service Account for APM Server:**

```sh
oc create serviceaccount apm-server -n elastic
```

**Add APM Service Account to `anyuid` SCC:**

```sh
oc adm policy add-scc-to-user anyuid -z apm-server -n elastic
```

Expected output: `scc "anyuid" added to: ["system:serviceaccount:elastic:apm-server"]`

**Deploy APM Server and Route:**

```yaml
cat <<EOF | oc apply -n elastic -f -
apiVersion: apm.k8s.elastic.co/v1
kind: ApmServer
metadata:
  name: apm-server-sample
spec:
  version: 8.17.3 # Match your Elasticsearch version
  count: 1
  elasticsearchRef:
    name: "elasticsearch-sample"
  podTemplate:
    spec:
      serviceAccountName: apm-server
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: apm-server-sample
spec:
  #host: apm-server.example.com # Override if you don't want the auto-generated host
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: apm-server-sample-apm-http
EOF
```

  * The APM Server serves as the TLS endpoint.

**Check APM Server Pod SCC:**

```sh
oc get pod -n elastic -o go-template='{{range .items}}{{$scc := index .metadata.annotations "openshift.io/scc"}}{{.metadata.name}}{{" scc:"}}{{range .spec.containers}}{{$scc}}{{" "}}{{"\n"}}{{end}}{{end}}'
```

Example output showing `apm-server-sample... scc:anyuid` and others with `scc:restricted`.

### 1.9. Verify Operator and Components

Verify the ECK operator pod is running in the `elastic-system` namespace:

```sh
oc get pods -n elastic-system
```

Verify Elasticsearch, Kibana, and APM Server pods are running in the `elastic` namespace:

```sh
oc get pods -n elastic
```

-----

## 2\. Access Kibana

### 2.1. Get Elastic User Password

To log into Kibana, retrieve the default `elastic` user password generated by ECK:

```sh
kubectl get secret elasticsearch-sample-es-elastic-user -n elastic -o go-template='{{.data.elastic | base64decode}}'
```

The username is `elastic`. This is standard ECK behavior for bootstrapping.

Use the retrieved password and the Kibana route URL (from `oc get route -n elastic`) to log in.

-----

## 3\. Configure Kibana: Index Templates & Lifecycle Policies

**Note:** For Elastic index templates you can also directly refer to helm chart templates: https://github.com/TIBCOSoftware/tp-helm-charts/tree/main/charts/dp-config-es/templates

These configurations are typically done via the Kibana UI (Stack Management \> Index Management) or a configuration management tool using Elasticsearch APIs.

### 3.1. User App Logs

#### 3.1.1. Create Index Lifecycle Policy: `user-index-60d-lifecycle-policy`

Define a lifecycle policy for user application logs (e.g., hot phase with rollover, delete phase after 60 days).

#### 3.1.2. Create Index Template: `user-app-index`

  * **Name:** `user-app-index`
  * **Index pattern:** `user-app-*`
  * **Index settings:**
    ```json
    {
      "index": {
        "lifecycle": {
          "name": "user-index-60d-lifecycle-policy",
          "rollover_alias": "user-apps"
        },
        "codec": "best_compression",
        "refresh_interval": "5s",
        "number_of_shards": "1",
        "number_of_replicas": "0"
      }
    }
    ```
  * **Mappings:** (Structure based on Elasticsearch mapping definitions)
    ```json
    {
      "properties": {
        "@timestamp": { "type": "date" },
        "Resource": {
          "properties": {
            "dataplane_id": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "pod_namespace": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "app_type": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "pod_uid": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "app_tags": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "app_id": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "workload_type": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "pod_name": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}}
          }
        },
        "Body": {
          "properties": {
            "log_level": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "message": { "type": "text", "fields": { "keyword": { "ignore_above": 256, "type": "keyword" }}},
            "log_time": { "type": "date" }
          }
        }
      }
    }
    ```
  * **Alias:**
    ```json
    {
      "user-apps": {}
    }
    ```
  * **Template Preview (Consolidated):**
    ```json
    {
      "index_patterns": ["user-app-*"],
      "template": {
        "settings": {
          "index": {
            "lifecycle": { "name": "user-index-60d-lifecycle-policy", "rollover_alias": "user-apps" },
            "codec": "best_compression",
            "routing": { "allocation": { "include": { "_tier_preference": "data_content" }}},
            "refresh_interval": "5s",
            "number_of_shards": "1",
            "number_of_replicas": "0"
          }
        },
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "Body": {
              "properties": {
                "log_level": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "log_time": { "type": "date" },
                "message": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}}
              }
            },
            "Resource": {
              "properties": {
                "app_id": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "app_tags": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "app_type": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "dataplane_id": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "pod_name": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "pod_namespace": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "pod_uid": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}},
                "workload_type": { "type": "text", "fields": { "keyword": { "type": "keyword", "ignore_above": 256 }}}
              }
            }
          }
        },
        "aliases": { "user-apps": {} }
      }
    }
    ```

-----

### 3.2. Jaeger Traces

#### 3.2.1. Create Index Lifecycle Policy: `jaeger-index-30d-lifecycle-policy`

This policy will be used for both Jaeger service and span indices.
Define via UI or API:

```json
{
  "policy": {
    "_meta": {
      "description": "this will be used for traces",
      "project": {
        "name": "jaeger",
        "department": "platform infra"
      }
    },
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_size": "2GB",
            "max_age": "7d"
          }
        }
      },
      "warm": {
        "min_age": "10d",
        "actions": {
          "forcemerge": {
            "max_num_segments": 1
          }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

#### 3.2.2. Create Jaeger Service Trace Index Template

  * **Name:** `jaeger-service-index-template`
  * **Index pattern:** `*jaeger-service-*`
  * **Index settings:** (Leverages Elasticsearch ILM and index settings)
    ```json
    {
      "index": {
        "lifecycle": {
          "name": "jaeger-index-30d-lifecycle-policy",
          "rollover_alias": "*jaeger-service-write"
        },
        "mapping": { "nested_fields": { "limit": "50" }},
        "requests": { "cache": { "enable": "true" }},
        "number_of_shards": "6",
        "number_of_replicas": "1"
      }
    }
    ```
  * **Mappings:** (Based on Jaeger's Elasticsearch schema requirements)
    ```json
    {
      "_data_stream_timestamp": { "enabled": true },
      "dynamic_templates": [
        { "span_tags_map": { "path_match": "tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}},
        { "process_tags_map": { "path_match": "process.tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}}
      ],
      "properties": {
        "@timestamp": { "type": "date" },
        "operationName": { "type": "keyword", "ignore_above": 256 },
        "serviceName": { "type": "keyword", "ignore_above": 256 }
      }
    }
    ```
  * **Aliases:**
    ```json
    {
      "jaeger-service-read": {}
    }
    ```
  * **Template Preview (Consolidated):**
    ```json
    {
      "index_patterns": ["*jaeger-service-*"],
      "template": {
        "settings": {
          "index": {
            "lifecycle": { "name": "jaeger-index-30d-lifecycle-policy", "rollover_alias": "*jaeger-service-write" },
            "routing": { "allocation": { "include": { "_tier_preference": "data_hot" }}},
            "mapping": { "nested_fields": { "limit": "50" }},
            "requests": { "cache": { "enable": "true" }},
            "number_of_shards": "6",
            "number_of_replicas": "1"
          }
        },
        "mappings": {
          "_data_stream_timestamp": { "enabled": true },
          "dynamic_templates": [
            { "span_tags_map": { "path_match": "tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}},
            { "process_tags_map": { "path_match": "process.tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}}
          ],
          "properties": {
            "@timestamp": { "type": "date" },
            "operationName": { "type": "keyword", "ignore_above": 256 },
            "serviceName": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "aliases": { "jaeger-service-read": {} }
      }
    }
    ```

#### 3.2.3. Create Jaeger Span Trace Index Template

  * **Name:** `jaeger-span-index-template`
  * **Index pattern:** `*jaeger-span-*`
  * **Index settings:** (Leverages Elasticsearch ILM and index settings)
    ```json
    {
      "index": {
        "lifecycle": {
          "name": "jaeger-index-30d-lifecycle-policy",
          "rollover_alias": "*jaeger-span-write"
        },
        "mapping": { "nested_fields": { "limit": "50" }},
        "requests": { "cache": { "enable": "true" }},
        "number_of_shards": "6",
        "number_of_replicas": "1"
      }
    }
    ```
  * **Mappings:** (Based on Jaeger's Elasticsearch schema requirements)
    ```json
    {
      "dynamic_templates": [
        { "span_tags_map": { "path_match": "tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}},
        { "process_tags_map": { "path_match": "process.tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}}
      ],
      "properties": {
        "duration": { "type": "long" },
        "flags": { "type": "integer" },
        "logs": {
          "type": "nested", "dynamic": "false",
          "properties": {
            "fields": {
              "type": "nested", "dynamic": "false",
              "properties": {
                "key": { "type": "keyword", "ignore_above": 256 },
                "tagType": { "type": "keyword", "ignore_above": 256 },
                "value": { "type": "keyword", "ignore_above": 256 }
              }
            },
            "timestamp": { "type": "long" }
          }
        },
        "operationName": { "type": "keyword", "ignore_above": 256 },
        "parentSpanID": { "type": "keyword", "ignore_above": 256 },
        "process": {
          "properties": {
            "serviceName": { "type": "keyword", "ignore_above": 256 },
            "tag": { "type": "object" },
            "tags": {
              "type": "nested", "dynamic": "false",
              "properties": {
                "key": { "type": "keyword", "ignore_above": 256 },
                "tagType": { "type": "keyword", "ignore_above": 256 },
                "value": { "type": "keyword", "ignore_above": 256 }
              }
            }
          }
        },
        "references": {
          "type": "nested", "dynamic": "false",
          "properties": {
            "refType": { "type": "keyword", "ignore_above": 256 },
            "spanID": { "type": "keyword", "ignore_above": 256 },
            "traceID": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "spanID": { "type": "keyword", "ignore_above": 256 },
        "startTime": { "type": "long" },
        "startTimeMillis": { "type": "date", "format": "epoch_millis" },
        "tag": { "type": "object" },
        "tags": {
          "type": "nested", "dynamic": "false",
          "properties": {
            "key": { "type": "keyword", "ignore_above": 256 },
            "tagType": { "type": "keyword", "ignore_above": 256 },
            "value": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "traceID": { "type": "keyword", "ignore_above": 256 }
      }
    }
    ```
  * **Aliases:**
    ```json
    {
      "jaeger-span-read": {}
    }
    ```
  * **Template Preview (Consolidated):**
    ```json
    {
      "index_patterns": ["*jaeger-span-*"],
      "template": {
        "settings": {
          "index": {
            "lifecycle": { "name": "jaeger-index-30d-lifecycle-policy", "rollover_alias": "*jaeger-span-write" },
            "routing": { "allocation": { "include": { "_tier_preference": "data_hot" }}},
            "mapping": { "nested_fields": { "limit": "50" }},
            "requests": { "cache": { "enable": "true" }},
            "number_of_shards": "6",
            "number_of_replicas": "1"
          }
        },
        "mappings": {
          "_data_stream_timestamp": { "enabled": true },
          "dynamic_templates": [
            { "span_tags_map": { "path_match": "tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}},
            { "process_tags_map": { "path_match": "process.tag.*", "mapping": { "ignore_above": 256, "type": "keyword" }}}
          ],
          "properties": {
            "@timestamp": { "type": "date" },
            "duration": { "type": "long" },
            "flags": { "type": "integer" },
            "logs": {
              "type": "nested", "dynamic": "false",
              "properties": {
                "fields": {
                  "type": "nested", "dynamic": "false",
                  "properties": {
                    "key": { "type": "keyword", "ignore_above": 256 },
                    "tagType": { "type": "keyword", "ignore_above": 256 },
                    "value": { "type": "keyword", "ignore_above": 256 }
                  }
                },
                "timestamp": { "type": "long" }
              }
            },
            "operationName": { "type": "keyword", "ignore_above": 256 },
            "parentSpanID": { "type": "keyword", "ignore_above": 256 },
            "process": {
              "properties": {
                "serviceName": { "type": "keyword", "ignore_above": 256 },
                "tag": { "type": "object" },
                "tags": {
                  "type": "nested", "dynamic": "false",
                  "properties": {
                    "key": { "type": "keyword", "ignore_above": 256 },
                    "tagType": { "type": "keyword", "ignore_above": 256 },
                    "value": { "type": "keyword", "ignore_above": 256 }
                  }
                }
              }
            },
            "references": {
              "type": "nested", "dynamic": "false",
              "properties": {
                "refType": { "type": "keyword", "ignore_above": 256 },
                "spanID": { "type": "keyword", "ignore_above": 256 },
                "traceID": { "type": "keyword", "ignore_above": 256 }
              }
            },
            "spanID": { "type": "keyword", "ignore_above": 256 },
            "startTime": { "type": "long" },
            "startTimeMillis": { "type": "date", "format": "epoch_millis" },
            "tag": { "type": "object" },
            "tags": {
              "type": "nested", "dynamic": "false",
              "properties": {
                "key": { "type": "keyword", "ignore_above": 256 },
                "tagType": { "type": "keyword", "ignore_above": 256 },
                "value": { "type": "keyword", "ignore_above": 256 }
              }
            },
            "traceID": { "type": "keyword", "ignore_above": 256 }
          }
        },
        "aliases": { "jaeger-span-read": {} }
      }
    }
    ```

-----

## 4\. Configure Prometheus

Prometheus is typically installed by default on OpenShift clusters as part of the cluster monitoring stack. To configure Prometheus scraping from a specific Data Plane (DP), you need to create a `ServiceMonitor` Custom Resource (CR) in the Data Plane's namespace.

### 4.1. Create ServiceMonitor for Data Plane Scraping

Use the following command to create the `ServiceMonitor` CR. This allows Prometheus to discover and scrape metrics from services (e.g., an OpenTelemetry Collector) in your Data Plane namespace.

```sh
export DP_NAMESPACE="dp1" # Replace "ns" with your actual Data Plane namespace

kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: otel-collector-monitor
  namespace: ${DP_NAMESPACE}
spec:
  endpoints:
  - interval: 30s
    path: /metrics
    port: prometheus
    scheme: http
  jobLabel: otel-collector
  selector:
    matchLabels:
      app.kubernetes.io/name: otel-userapp-metrics
EOF
```

**Note:** You need to create a `ServiceMonitor` like the one above for **all** Data Plane namespaces from which you want to scrape metrics.

### 4.2. Accessing Metrics from Outside the Cluster (Querying Prometheus)

OpenShift's built-in Prometheus (via Thanos Querier) does not support username/password authentication by default for external queries. You'll need to use a token. For details on accessing monitoring APIs, refer to the OpenShift documentation on [accessing metrics from outside the cluster](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/monitoring/accessing-metrics.html%23accessing-monitoring-apis-by-using-the-cli_accessing-metrics).

#### 4.2.1. Using a Short-Lived Token

1.  **Extract the Thanos Querier API route URL:**

    ```sh
    HOST=$(oc -n openshift-monitoring get route thanos-querier -ojsonpath='{.status.ingress[].host}')
    echo "Thanos Querier URL: https://\${HOST}"
    ```

2.  **Extract an authentication token for your current logged-in user:**

    ```sh
    TOKEN=$(oc whoami -t)
    echo "Token: \${TOKEN}"
    ```

3.  **Use the token in the Authorization header to query Thanos Querier:**
    You can use this token with tools like `curl` or in your Data Plane's configuration:

    ```
    "Authorization: Bearer $TOKEN"
    ```

    For example, with `curl`:

    ```sh
    curl -k -H "Authorization: Bearer \${TOKEN}" "https://\${HOST}/api/v1/query?query=up"
    ```

**Note:** The token obtained via `oc whoami -t` is short-lived and will require frequent rotation if used in automated systems.

#### 4.2.2. Using a More Persistent Service Account Token

For a more persistent solution, create a Service Account with appropriate permissions that can provide tokens with extended validity.

1.  **Create a Service Account in the `openshift-monitoring` namespace:**

    ```sh
    oc create sa thanos-client -n openshift-monitoring
    ```

2.  **Grant the Service Account cluster monitoring view permissions:**

    ```sh
    oc adm policy add-cluster-role-to-user cluster-monitoring-view -z thanos-client -n openshift-monitoring
    ```

3.  **Create a token for the Service Account:**

    ```sh
    # For OpenShift 4.11+
    TOKEN=$(oc create token thanos-client -n openshift-monitoring --duration=8760h) # Example: 1 year duration
    # For older OpenShift versions, you might need to extract the token from the SA's secret:
    # SA_SECRET_NAME=$(oc get sa thanos-client -n openshift-monitoring -ojsonpath='{.secrets[0].name}')
    # TOKEN=$(oc get secret ${SA_SECRET_NAME} -n openshift-monitoring -ojsonpath='{.data.token}' | base64 --decode)
    echo "Service Account Token: \${TOKEN}"
    ```

4.  **Use the Service Account token in the Authorization header:**
    Similar to the short-lived token, use this token in your Authorization header:

    ```
    "Authorization: Bearer $TOKEN"
    ```

    This token will be valid for the duration specified (or as per cluster policy) and is more suitable for programmatic access.

#### 4.3 Enable monitoring for user-defined projects

[Openshift Ref: Enabling monitoring for user-defined projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/configuring-user-workload-monitoring#enabling-monitoring-for-user-defined-projects_preparing-to-configure-the-monitoring-stack-uwm)

```yaml
oc -n openshift-monitoring get configmap cluster-monitoring-config -o yaml
apiVersion: v1
data:
  config.yaml: |
    enableUserWorkload: true
kind: ConfigMap
metadata:
  creationTimestamp: "2025-06-02T13:05:02Z"
  name: cluster-monitoring-config
  namespace: openshift-monitoring
  resourceVersion: "1662902"
  uid: 09ee4eaa-5548-417f-b02d-3723777672d9
```
#### 4.4. Handling Thanos Router URL with Default `/api` Endpoint

When configuring the TIBCO Platform `o11y-service` to connect to a Thanos Router (or any endpoint that already includes a base `/api` path), an issue with URL construction may occur. The `o11y-service` internally appends a path like `/api/v1/query` to the provided base URL. If your Thanos Router URL already ends with `/api`, this can result in a malformed path such as `.../api/api/v1/query`, leading to query failures.

**Resolution:**
Ensure that the base URL configured for the Thanos Router in your `o11y-service` does not include `/api` if the `o11y-service` is designed to append it. Provide only the hostname and port, allowing the `o11y-service` to correctly construct the full path. For example, if your Thanos Router is accessible at `thanos-router.example.com/api`, configure `o11y-service` with `thanos-router.example.com` (or equivalent Kubernetes service URL).

---

#### 4.5. Troubleshooting Thanos Internal Cluster URL with HTTPS

OpenShift's native Thanos Querier is typically configured to serve metrics securely over HTTPS, especially on ports like `9091` (for PromQL queries). Communication usually requires TLS and authentication via a Service Account bearer token.

**Observed Behavior:**
During integration of `o11y-service` with Thanos Querier via its internal Cluster Service URL (`thanos-querier.openshift-monitoring.svc.cluster.local:9091`), the following was observed:
- `curl` tests from within the cluster successfully connected to the HTTPS endpoint and consistently failed on the HTTP endpoint (as expected for an HTTPS-only service).
- However, the `o11y-service` could not establish a connection over HTTPS, even after injecting the necessary CA certificate.
- Surprisingly, the `o11y-service` was able to connect successfully over HTTP to `thanos-querier.openshift-monitoring.svc.cluster.local:9091`, which contradicts direct `curl` observations and the expected secure configuration of Thanos Querier.

This suggests an underlying issue with how `o11y-service`'s internal HTTP client handles TLS or network interactions within the ARO environment.

---

**Workaround: Certificate Injection**

Since the `o11y-service` requires proper TLS validation (it lacks an `--insecure` option), a custom CA certificate bundle was injected into the `o11y-service` pod to enable trust in the Thanos Querier's TLS certificate.

**Steps to Implement the Certificate Workaround:**

1. **Obtain the Thanos Querier CA Certificate:**
  Extract the CA certificate that signed the Thanos Querier's certificate from your OpenShift cluster. This is often the cluster's internal CA. Consult OpenShift documentation or a cluster administrator for the exact method.

2. **Create a ConfigMap with the Certificate:**
  Create a Kubernetes ConfigMap in the same namespace as your `o11y-service` deployment (e.g., `dp5`). Name this ConfigMap `o11y-service-to-thanos-querier-cm`.

  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: o11y-service-to-thanos-querier-cm
    namespace: dp5 # Ensure this matches the namespace of your o11y-service
  data:
    ca-certificate-thanos.crt: |
     -----BEGIN CERTIFICATE-----
     # Paste your Thanos Querier CA certificate content here
     -----END CERTIFICATE-----
  ```

  Apply this ConfigMap:
  ```sh
  oc apply -f <your-configmap-file.yaml> -n dp5
  ```

3. **Update the `o11y-service` Deployment:**
  Modify the `o11y-service` Deployment YAML to mount this new ConfigMap into the `tp-o11y-service` container. This will place your custom CA certificate at `/etc/ssl/certs/ca-certificate-thanos.crt`.

  Add the following to your `spec.template.spec.volumes` section:
  ```yaml
  volumes:
    - name: custom-ca-bundle-volume
     configMap:
      name: o11y-service-to-thanos-querier-cm
      items:
      - key: ca-certificate-thanos.crt
        path: ca-certificate-thanos.crt
      defaultMode: 420
  ```

  Add the following to your `containers.tp-o11y-service.volumeMounts` section:
  ```yaml
  volumeMounts:
    - name: custom-ca-bundle-volume
     mountPath: /etc/ssl/certs/ca-certificate-thanos.crt
     subPath: ca-certificate-thanos.crt
     readOnly: true
  ```

  Apply the updated Deployment:
  ```sh
  oc apply -f <your-deployment-file.yaml> -n dp5
  ```

---

**Final Configuration Observation:**
After performing the certificate injection, if the HTTPS connection still fails for `o11y-service`, you might need to configure the `o11y-service` with the HTTP URL for the internal Thanos Querier service. While this behavior is unexpected given Thanos Querier's default HTTPS-only configuration on port `9091`, it proved to be a functional workaround in this specific environment.

**Note:** The successful connection over HTTP after certificate injection is highly unusual for a standard Thanos Querier setup that enforces HTTPS. This documentation reflects a specific workaround found necessary in a particular ARO environment and may indicate an underlying anomaly in that environment or `o11y-service`'s network client behavior.
-----

## 5\. Reference Links

### Elastic Stack (ECK, Elasticsearch, Kibana)

  * **Elastic Cloud on Kubernetes (ECK) General Documentation:** [https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)
  * **ECK Quickstart (Self-Managed YAML Install):** [https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart-self-managed.html](https://www.google.com/url?sa=E&source=gmail&q=https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart-self-managed.html)
  * **ECK on OpenShift Specifics:** [https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-openshift.html)
  * **Elasticsearch `vm.max_map_count` Setting:** [https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html)
  * **ECK Custom Images (for plugins):** [https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-custom-images.html](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-custom-images.html)
  * **Elasticsearch Index Templates:** [https://www.elastic.co/guide/en/elasticsearch/reference/current/index-templates.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-templates.html)
  * **Elasticsearch Index Lifecycle Management (ILM):** [https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-lifecycle-management.html)
  * **Elasticsearch Mappings:** [https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)

### Jaeger

  * **Jaeger Deployment with Elasticsearch:** [https://www.jaegertracing.io/docs/latest/deployment/\#elasticsearch](https://www.google.com/search?q=https://www.jaegertracing.io/docs/latest/deployment/%23elasticsearch)
      * (The specific index template JSONs are highly dependent on Jaeger version and desired schema; refer to Jaeger and Elastic APM/Jaeger integration documentation for the most current details.)

### OpenShift

  * **OpenShift CLI (`oc`) Reference:** [https://docs.openshift.com/container-platform/latest/cli\_reference/index.html](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/cli_reference/index.html)
  * **OpenShift Monitoring Overview:** [https://docs.openshift.com/container-platform/latest/monitoring/index.html](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/monitoring/index.html)
  * **OpenShift ServiceMonitors (Managing Metrics):** [https://docs.openshift.com/container-platform/latest/monitoring/managing-metrics.html\#specifying-how-a-service-is-monitored\_managing-metrics](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/monitoring/managing-metrics.html%23specifying-how-a-service-is-monitored_managing-metrics)
  * **Accessing OpenShift Monitoring APIs (Thanos Querier, Tokens):** [https://docs.openshift.com/container-platform/latest/monitoring/accessing-metrics.html\#accessing-monitoring-apis-by-using-the-cli\_accessing-metrics](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/monitoring/accessing-metrics.html%23accessing-monitoring-apis-by-using-the-cli_accessing-metrics)
  * **OpenShift Service Accounts:** [https://docs.openshift.com/container-platform/latest/authentication/understanding-and-creating-service-accounts.html](https://www.google.com/search?q=https://docs.openshift.com/container-platform/latest/authentication/understanding-and-creating-service-accounts.html)

### Kubernetes

  * **`kubectl` Command Reference:** [https://kubernetes.io/docs/reference/kubectl/](https://kubernetes.io/docs/reference/kubectl/)
  * **Viewing and Finding Kubernetes Resources (Secrets):** [https://kubernetes.io/docs/reference/kubectl/view-resources/](https://www.google.com/search?q=https://kubernetes.io/docs/reference/kubectl/view-resources/)

-----

```
```

## Information needed to be set on TIBCO® Data Plane

You can get BASE_FQDN (fully qualified domain name) by running the command mentioned in [DNS](#dns) section.

| Name                 | Sample value                                                                     | Notes                                                                     |
|:---------------------|:---------------------------------------------------------------------------------|:--------------------------------------------------------------------------|
| Node / Pod CIDR             | 10.0.2.0/23                                                                    | from Worker Node subnet (Check [TP_WORKER_SUBNET_CIDR in cluster-setup](../cluster-setup/README.md#export-required-variables)                                      |
| Service CIDR             | 172.30.0.0/16                                                                    | Run the command az aro show -g ${TP_RESOURCE_GROUP} -n ${TP_CLUSTER_NAME} --query networkProfile.serviceCidr -o tsv                                        |
| Pod CIDR             | 10.128.0.0/14                                                                    |  Run the command az aro show -g ${TP_RESOURCE_GROUP} -n ${TP_CLUSTER_NAME} --query networkProfile.podCidr -o tsv                                        |
| Ingress class name   | openshift-default                                                                            | used for TIBCO BusinessWorks™ Container Edition                                                     |
| Azure Files storage class    | azure-files-sc                                                                           | used for TIBCO BusinessWorks™ Container Edition and TIBCO Enterprise Message Service™ (EMS) Azure Files storage                                         |
| Azure Files storage class    | azure-files-sc-ems                                                                          | used for TIBCO Enterprise Message Service™ (EMS)                                             |
| Azure Disk storage class    | azure-disk-sc                                                                          | disk storage can be used for data plane capabilities, in general                                               |
| BW FQDN              | bwce.\<BASE_FQDN\>                                                               | Capability FQDN |
Network Policies Details for Data Plane Namespace | [Data Plane Network Policies Document](https://docs.tibco.com/pub/platform-cp/latest/doc/html/Default.htm#UserGuide/controlling-traffic-with-network-policies.htm) |


## Screenshots adding observability: 

### Screenshots

Below are screenshots illustrating the observability setup steps on OpenShift ARO. Images are shown in the order they appear in the folder.



#### 1. observability-dp-add-logs-query-service.png

![observability-dp-add-logs-query-service.png](../diagrams/openshift-azure-aro-dp-observability/observability-dp-add-logs-query-service.png)

#### 2. observability-dp-add-metrics-query-service-thanos.png

Note: Use url: https://thanos-querier-openshift-monitoring.apps.yyxyzx4x.westeurope.aroapp.io
(without any api suffix, e.g. /v1/ etc)
Use customer headers with: 
 Key = Authorization
 Value = Bearer $TOKEN
Do not use any username password.


![observability-dp-add-metrics-query-service-thanos.png](../diagrams/openshift-azure-aro-dp-observability/observability-dp-add-metrics-query-service-thanos.png)

#### 3. Observability Traces Query service

![observability-dp-add-traces-query.png](../diagrams/openshift-azure-aro-dp-observability/observability-dp-add-traces-query.png)

#### 4. Observability Traces exporter

![observability-dp-add-traces-exporter.png](../diagrams/openshift-azure-aro-dp-observability/observability-dp-add-traces-exporter.png)

#### 5. Observability config log server

![observability-aro-logs-server config](../diagrams/openshift-azure-aro-dp-observability/observability-aro-logs-server.png)

#### 6. Observability config metrics server

![observability-aro-metrics-server config](../diagrams/openshift-azure-aro-dp-observability/observability-aro-metrics-server.png)

#### 7. Observability Resouce Trace Server

![observability-aro-traces-server config](../diagrams/openshift-azure-aro-dp-observability/observability-aro-traces-server.png)


