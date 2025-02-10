## Cluster configuration specific variables
export TP_CLUSTER_NAME="minikube" # name of the cluster to be provisioned, used for chart deployment
#export KUBECONFIG=`pwd`/${TP_CLUSTER_NAME}.yaml # kubeconfig saved as cluster name yaml

## By default, only your public IP will be added to allow access to public cluster
#export TP_AUTHORIZED_IP=""  # declare additional IPs to be whitelisted for accessing cluster

## Tooling specific variables
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts # location of charts repo url
export TP_DOMAIN="localhost.dataplanes.pro" # domain to be used
export TP_DISK_ENABLED="true" # to enable azure disk storage class
export TP_DISK_STORAGE_CLASS="standard" # name of azure disk storage class
export TP_FILE_ENABLED="true" # to enable azure files storage class
export TP_FILE_STORAGE_CLASS="standard" # name of azure files storage class
export TP_INGRESS_CLASS="nginx" # name of main ingress class used by capabilities, use 'traefik' for traefik ingress controller
export TP_ES_RELEASE_NAME="dp-config-es" # name of dp-config-es release name
export TP_DNS_RESOURCE_GROUP="" # replace with name of resource group containing dns record sets
export TP_NETWORK_POLICY="" # possible values "" (to disable network policy), "calico"
#export TP_STORAGE_ACCOUNT_NAME="" # replace with name of existing storage account to be used for azure file shares
#export TP_STORAGE_ACCOUNT_RESOURCE_GROUP="" # replace with name of storage account resource group

echo "Install nginx ingress controller if not installed already"
kubectl get pods -n ingress-system | grep nginx-ingress-controller || helm upgrade --install --wait --timeout 1h --create-namespace -n ingress-system nginx ingress-nginx --repo "https://kubernetes.github.io/ingress-nginx" --version "4.0.0"

kubectl get ingressclass -A

echo "Install Elastic stack"

helm upgrade --install --wait --timeout 1h --labels layer=1 --create-namespace -n elastic-system eck-operator eck-operator --repo "https://helm.elastic.co" --version "2.9.0"

# install dp-config-es
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
    -n elastic-system ${TP_ES_RELEASE_NAME} dp-config-es \
    --labels layer=2 \
    --repo "${TP_TIBCO_HELM_CHART_REPO}" --version "1.0.17" -f - <<EOF
domain: ${TP_DOMAIN}
es:
    version: "8.9.1"
    ingress:
        ingressClassName: ${TP_INGRESS_CLASS}
        service: ${TP_ES_RELEASE_NAME}-es-http
    storage:
        name: ${TP_DISK_STORAGE_CLASS}
kibana:
    version: "8.9.1"
    ingress:
        ingressClassName: ${TP_INGRESS_CLASS}
        service: ${TP_ES_RELEASE_NAME}-kb-http
apm:
    enabled: true
    version: "8.9.1"
    ingress:
        ingressClassName: ${TP_INGRESS_CLASS}
        service: ${TP_ES_RELEASE_NAME}-apm-http
EOF

echo "Kibana URL"
kubectl get ingress -n elastic-system ${TP_ES_RELEASE_NAME}-kb-http -o jsonpath='{.spec.rules[0].host}' && echo

echo "Elasticsearch Username"
kubectl get secret -n elastic-system ${TP_ES_RELEASE_NAME}-es-elastic-user -o jsonpath='{.data.elastic}' | base64 --decode && echo

echo "Elasticsearch Password"
kubectl get secret -n elastic-system ${TP_ES_RELEASE_NAME}-es-elastic-user -o jsonpath='{.data.password}' | base64 --decode && echo

echo "APM URL"
kubectl get ingress -n elastic-system ${TP_ES_RELEASE_NAME}-apm-http -o jsonpath='{.spec.rules[0].host}' && echo

echo "\n"
echo "-----------------------------"
echo "Install Prometheus Stack"

# install prometheus stack
helm upgrade --install --wait --timeout 1h --create-namespace --reuse-values \
    -n prometheus-system kube-prometheus-stack kube-prometheus-stack \
    --labels layer=2 \
    --repo "https://prometheus-community.github.io/helm-charts" --version "48.3.4" -f <(envsubst '${TP_DOMAIN}, ${TP_INGRESS_CLASS}' <<'EOF'
grafana:
    plugins:
        - grafana-piechart-panel
    ingress:
        enabled: true
        ingressClassName: ${TP_INGRESS_CLASS}
        hosts:
        - grafana.${TP_DOMAIN}
prometheus:
    prometheusSpec:
        enableRemoteWriteReceiver: true
        remoteWriteDashboards: true
        additionalScrapeConfigs:
        - job_name: otel-collector
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            - action: keep
                regex: "true"
                source_labels:
                - __meta_kubernetes_pod_label_prometheus_io_scrape
            - action: keep
                regex: "infra"
                source_labels:
                - __meta_kubernetes_pod_label_platform_tibco_com_workload_type
            - action: keepequal
                source_labels: [__meta_kubernetes_pod_container_port_number]
                target_label: __meta_kubernetes_pod_label_prometheus_io_port
            - action: replace
                regex: ([^:]+)(?::\d+)?;(\d+)
                replacement: $1:$2
                source_labels:
                - __address__
                - __meta_kubernetes_pod_label_prometheus_io_port
                target_label: __address__
            - source_labels: [__meta_kubernetes_pod_label_prometheus_io_path]
                action: replace
                target_label: __metrics_path__
                regex: (.+)
                replacement: /$1
    ingress:
        enabled: true
        ingressClassName: ${TP_INGRESS_CLASS}
        hosts:
        - prometheus-internal.${TP_DOMAIN}
EOF
)

echo "Use this command to get the host URL for Kibana"
kubectl get ingress -n prometheus-system kube-prometheus-stack-grafana -oyaml | yq eval '.spec.rules[0].host' && echo

echo "The username is admin. And Prometheus Operator use fixed password: prom-operator."

echo "You can get BASE_FQDN (fully qualified domain name) by running the following command:"

kubectl get ingress -n ingress-system nginx |  awk 'NR==2 { print $3 }' && echo
