#!/bin/bash

curl -fsSL https://raw.githubusercontent.com/tibco-bnl/workshop-tibco-platform/dataplane-on-k8s-in-wsl/3.%20Dataplane-on-k8s-on-WSL/bin/replaceguienvvar.sh -o  replaceguienvvar.sh
chmod +x replaeguienvvar.sh
curl -fsSL https://raw.githubusercontent.com/TIBCOSoftware/platform-provisioner/master/docs/recipes/tp-base/tp-base-on-prem.yaml -o tp-base-on-prem.yaml
export PIPELINE_INPUT_RECIPE="tp-base-on-prem.yaml"
./replaceguienvvar.sh GUI_TP_INSTALL_PROVISIONER_UI \"false\" tp-base-on-prem.yaml
./replaceguienvvar.sh GUI_TP_STORAGE_CLASS \"hostpath\" tp-base-on-prem.yaml
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/TIBCOSoftware/platform-provisioner/main/dev/platform-provisioner.sh)"
