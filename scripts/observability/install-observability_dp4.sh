#!/bin/bash

## Cluster configuration specific variables
#export TP_CLUSTER_NAME="dp4-aks-presalesnl" # name of the cluster to be provisioned, used for chart deployment
export TP_CLUSTER_NAME="dp4-aks-presalesnl" # name of the cluster to be provisioned, used for chart deployment
#export KUBECONFIG=`pwd`/${TP_CLUSTER_NAME}.yaml # kubeconfig saved as cluster name yaml

## By default, only your public IP will be added to allow access to public cluster
#export TP_AUTHORIZED_IP=""  # declare additional IPs to be whitelisted for accessing cluster

## Tooling specific variables
export TP_TIBCO_HELM_CHART_REPO=https://tibcosoftware.github.io/tp-helm-charts # location of charts repo url
#export TP_DOMAIN="mle.atsnl-emea.azure.dataplanes.pro" # domain to be used
export TP_DOMAIN="mle.atsnl-emea.azure.dataplanes.pro" # domain to be used
export TP_DISK_ENABLED="true" # to enable azure disk storage class
export TP_DISK_STORAGE_CLASS="azure-disk-sc" # name of azure disk storage class
export TP_FILE_ENABLED="true" # to enable azure files storage class
export TP_FILE_STORAGE_CLASS="azure-files-sc" # name of azure files storage class
export TP_INGRESS_CLASS="nginx" # name of main ingress class used by capabilities, use 'traefik' for traefik ingress controller
export TP_ES_RELEASE_NAME="dp-config-es" # name of dp-config-es release name
export TP_DNS_RESOURCE_GROUP="" # replace with name of resource group containing dns record sets
export TP_NETWORK_POLICY="" # possible values "" (to disable network policy), "calico"
#export TP_STORAGE_ACCOUNT_NAME="" # replace with name of existing storage account to be used for azure file shares
#export TP_STORAGE_ACCOUNT_RESOURCE_GROUP="" # replace with name of storage account resource group

install_nginx() {
    echo "Install nginx ingress controller if not installed already"
    kubectl get pods -n ingress-system | grep nginx-ingress-controller || helm upgrade --install --wait --create-namespace -n ingress-system nginx ingress-nginx --repo "https://kubernetes.github.io/ingress-nginx" --version "4.10.1"
    kubectl get ingressclass -A
}

install_elastic() {
    echo "Install Elastic stack"
    helm upgrade --install --wait --labels layer=1 --create-namespace -n elastic-system eck-operator eck-operator --repo "https://helm.elastic.co" --version "2.16.0"

    # install dp-config-es
    helm upgrade --install --wait --create-namespace --reuse-values \
        -n elastic-system dp-config-es dp-config-es \
        --labels layer=2 \
        --repo "${TP_TIBCO_HELM_CHART_REPO}" --version "^1.0.0" -f - <<EOF
domain: ${TP_DOMAIN}
es:
    version: "8.17.3"
    ingress:
        ingressClassName: nginx
        service: dp-config-es-es-http
    storage:
        name: azure-disk-sc
kibana:
    version: "8.17.3"
    ingress:
        ingressClassName: nginx
        service: dp-config-es-kb-http
apm:
    enabled: true
    version: "8.17.3"
    ingress:
        ingressClassName: nginx
        service: dp-config-es-apm-http
EOF

    echo "Elasticsearch Password"
    kubectl get secret -n elastic-system dp-config-es-es-elastic-user -o jsonpath='{.data.elastic}' | base64 --decode && echo

    echo "Print ingresses"
    kubectl get ingress -n elastic-system -o json | jq -r '.items[] | "https://\(.spec.rules[0].host)"'
}

install_prometheus() {
    echo "Install Prometheus Stack"
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

    echo "Prometheus and Grafana URLs"
    kubectl get ingress -n prometheus-system -o json | jq -r '.items[] | "https://\(.spec.rules[0].host)"'
    echo "username:admin. And Prometheus Operator use fixed password: prom-operator."

    echo "You can get BASE_FQDN (fully qualified domain name) by running the following command:"
    kubectl get ingress -n ingress-system nginx |  awk 'NR==2 { print $3 }' && echo
}

port_forward() {
    # Port forward Elastic, Kibana, Grafana, Prometheus
    echo "Port forward Elastic, Kibana, Grafana, Prometheus"
    echo "Release name: ${TP_ES_RELEASE_NAME}"
     nohup sudo kubectl port-forward -n elastic-system --address 0.0.0.0 svc/${TP_ES_RELEASE_NAME}-es-http 9200:9200 &  >/dev/null 2>&1 &
     nohup sudo kubectl port-forward -n elastic-system --address 0.0.0.0 svc/${TP_ES_RELEASE_NAME}-kb-http 5601:5601 &  >/dev/null 2>&1 &
     nohup sudo kubectl port-forward -n prometheus-system --address 0.0.0.0 svc/kube-prometheus-stack-grafana 3000:80 & >/dev/null 2>&1 &
     nohup sudo kubectl port-forward -n prometheus-system --address 0.0.0.0 svc/kube-prometheus-stack-prometheus 9090:9090 & >/dev/null 2>&1 &



    echo "To stop the port forwarding, run the following commands:"
    echo "kill elastic $(lsof -t -i:9200)"
    echo "kill kibana $(lsof -t -i:5601)"
    echo "kill grafana $(sudo lsof -t -i:3000)"
    echo "kill prometheus $(sudo lsof -t -i:9090)"
    
    echo "All URLS: "
    echo "Elastic url to use in DP: https://dp-config-es-es-http.elastic-system.svc.cluster.local:9200"
    echo "For Kibana username is elastic and password "
    kubectl get secret -n elastic-system dp-config-es-es-elastic-user -o jsonpath='{.data.elastic}' | base64 --decode && echo

    echo "For Prometheus username password"
    echo "Username: admin"
    echo "Password: prom-operator"
}

case "$1" in
    all)
        install_nginx
        install_elastic
        install_prometheus
        ;;
    nginx)
        install_nginx
        ;;
    elastic)
        install_elastic
        ;;
    prometheus)
        install_prometheus
        ;;
    port-forward)
        port_forward
        ;;
    *)
        echo "Usage: $0 {all|nginx|elastic|prometheus|port-forward}"
        exit 1
        ;;
esac
