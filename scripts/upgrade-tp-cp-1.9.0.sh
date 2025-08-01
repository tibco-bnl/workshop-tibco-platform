#!/bin/bash

# Define the Control Plane Namespace
CONTROL_PLANE_NAMESPACE="cp1-ns"

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

# Step 5: Upgrade platform-bootstrap chart
echo "Upgrading platform-bootstrap chart..."
helm upgrade --install -n $CONTROL_PLANE_NAMESPACE platform-bootstrap tibco-platform/platform-bootstrap -f platform-bootstrap-values.yaml --version=1.9.0

# Step 6: Upgrade platform-base chart
echo "Upgrading platform-base chart..."
helm upgrade --install -n $CONTROL_PLANE_NAMESPACE platform-base tibco-platform/platform-base -f platform-base-values.yaml --version=1.9.0

echo "Upgrade process completed successfully."