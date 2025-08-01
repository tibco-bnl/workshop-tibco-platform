#!/bin/bash

# Define the Control Plane Namespace
CONTROL_PLANE_NAMESPACE="cp1-ns"

# Define environment variables
# Define environment variables
CP_GLOBAL_ENABLE_RESOURCE_CONSTRAINTS=${GUI_CP_GLOBAL_ENABLE_RESOURCE_CONSTRAINTS:-true}
CP_NODE_CIDR=${GUI_TP_CLUSTER_NODE_CIDR:-"10.180.0.0/16"}
CP_POD_CIDR=${GUI_TP_CLUSTER_POD_CIDR:-"10.180.0.0/16"}
CP_SERVICE_CIDR=${GUI_TP_SERVICE_CIDR:-"10.96.0.0/12"}
CP_SERVICE_DNS_DOMAIN=${CP_INSTANCE_ID}-my.${CP_DNS_DOMAIN}
CP_CONTAINER_REGISTRY=${GUI_CP_CONTAINER_REGISTRY:-"csgprduswrepoedge.jfrog.io"}
CP_CONTAINER_REGISTRY_REPOSITORY=${GUI_CP_CONTAINER_REGISTRY_REPOSITORY:-"tibco-platform-docker-prod"}
CP_CONTAINER_REGISTRY_USERNAME="${GUI_CP_CONTAINER_REGISTRY_USERNAME}"
CP_CONTAINER_REGISTRY_PASSWORD="${GUI_CP_CONTAINER_REGISTRY_PASSWORD}"
CP_INSTANCE_ID=${GUI_CP_INSTANCE_ID:-"cp1"}
CP_CREATE_NETWORK_POLICIES=${GUI_CP_CREATE_NETWORK_POLICIES:-false}
CP_GLOBAL_USE_SINGLE_NAMESPACE=${GUI_CP_GLOBAL_USE_SINGLE_NAMESPACE:-true}
CP_LOG_ENABLE=${GUI_CP_LOG_ENABLE:-false}

# Step 1: Create the session-keys secret required by platform-bootstrap chart
echo "Creating session-keys secret..."
TSC_SESSION_KEY=$(kubectl get tibcoclusterenv ops.tsc.session.key -n $CONTROL_PLANE_NAMESPACE -o jsonpath='{.spec.value}')
DOMAIN_SESSION_KEY=$(kubectl get tibcoclusterenv ops.domain.session.key -n $CONTROL_PLANE_NAMESPACE -o jsonpath='{.spec.value}')

kubectl create secret generic session-keys -n $CONTROL_PLANE_NAMESPACE \
    --from-literal=TSC_SESSION_KEY=$TSC_SESSION_KEY \
    --from-literal=DOMAIN_SESSION_KEY=$DOMAIN_SESSION_KEY

# Step 2: Create the cporch-encryption-secret secret required by platform-base chart
echo "Backing up and annotating cporch-encryption-secret..."
kubectl get secret cporch-encryption-secret -n $CONTROL_PLANE_NAMESPACE -o yaml > cporch-encryption-secret.yaml
kubectl annotate secret cporch-encryption-secret helm.sh/resource-policy=keep --overwrite -n $CONTROL_PLANE_NAMESPACE

# Step 3: Update local Helm repo with the latest charts
echo "Updating Helm repo..."
helm repo update

# Step 4: Fetch the current values of Helm charts installed
echo "Fetching current Helm chart values..."
helm get values -n $CONTROL_PLANE_NAMESPACE platform-bootstrap > platform-bootstrap-values.yaml
helm get values -n $CONTROL_PLANE_NAMESPACE platform-base > platform-base-values.yaml

# Update platform-bootstrap-values.yaml to remove tp-cp-bootstrap section and restructure values
echo "Updating platform-bootstrap-values.yaml to reflect chart restructuring..."
yq eval 'del(.tp-cp-bootstrap) |
    .hybridProxy = .tp-cp-bootstrap.hybridProxy |
    .resourceSetOperator = .tp-cp-bootstrap.resourceSetOperator |
    .routerOperator = .tp-cp-bootstrap.routerOperator |
    .computeServices = .tp-cp-bootstrap.computeServices |
    .otelCollector = .tp-cp-bootstrap.otelCollector' \
    platform-bootstrap-values.yaml > platform-bootstrap-values-updated.yaml

mv platform-bootstrap-values-updated.yaml platform-bootstrap-values.yaml

# Step 5: Modify platform-base values file with the required changes
echo "Modifying platform-base values file..."
yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' platform-base-values.yaml - <<EOF > platform-base-values-merged.yaml
global:
    cp:
        enableResourceConstraints: ${CP_GLOBAL_ENABLE_RESOURCE_CONSTRAINTS}
    external:
        clusterInfo:
            nodeCIDR: ${CP_NODE_CIDR}
            podCIDR: ${CP_POD_CIDR}
            serviceCIDR: ${CP_SERVICE_CIDR}
        dnsDomain: ${CP_SERVICE_DNS_DOMAIN}
        enableLogging: false
        cpEncryptionSecretName: "${CP_ENCRYPTION_SECRET_NAME}"
        cpEncryptionSecretKey: "${CP_ENCRYPTION_SECRET_KEY}"
    tibco:
        containerRegistry:
            url: ${CP_CONTAINER_REGISTRY}
            repository: ${CP_CONTAINER_REGISTRY_REPOSITORY}
            username: ${CP_CONTAINER_REGISTRY_USERNAME}
            password: ${CP_CONTAINER_REGISTRY_PASSWORD}
        controlPlaneInstanceId: ${CP_INSTANCE_ID}
        createNetworkPolicy: ${CP_CREATE_NETWORK_POLICIES}
        enableResourceConstraints: ${CP_GLOBAL_ENABLE_RESOURCE_CONSTRAINTS}
        logging:
            fluentbit:
                enabled: ${CP_LOG_ENABLE}
        serviceAccount: ${CP_INSTANCE_ID}-sa
        useSingleNamespace: ${CP_GLOBAL_USE_SINGLE_NAMESPACE}

dp-oauth2proxy-recipes:
    capabilities:
        oauth2proxy:
            overwriteRecipe: "true"
tp-cp-configuration:
    capabilities:
        cpproxy:
            overwriteRecipe: "true"
        integrationcore:
            overwriteRecipe: "true"
tp-cp-o11y:
    capabilities:
        o11y:
            default:
                overwriteRecipe: "true"
            withResources:
                overwriteRecipe: "true"
tp-cp-core-finops:
    capabilities:
        monitorAgent:
            overwriteRecipe: "true"
tp-cp-hawk-console-recipes:
    capabilities:
        hawkConsole:
            overwriteRecipe: "true"
EOF

mv platform-base-values-merged.yaml platform-base-values.yaml

# Step 6: Upgrade platform-bootstrap chart
echo "Upgrading platform-bootstrap chart..."
helm upgrade --install -n $CONTROL_PLANE_NAMESPACE platform-bootstrap tibco-platform/platform-bootstrap -f platform-bootstrap-values.yaml --version=1.9.0

# Step 7: Upgrade platform-base chart
echo "Upgrading platform-base chart..."
helm upgrade --install -n $CONTROL_PLANE_NAMESPACE platform-base tibco-platform/platform-base -f platform-base-values.yaml --version=1.9.0

echo "Upgrade process completed successfully."