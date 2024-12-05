
1.  ~/git/platform-provisioner | on main  ./dev/platform-provisioner-pipelinerun.sh                                          ok | % | at 11:52:09 AM
create tekton "generic-runner" pipelinerun on-prem-74 for admin
error: error parsing STDIN: error converting YAML to JSON: yaml: line 5: did not find expected key
kubectl apply error

- Solution:
'''

'''

2. ./dev/platform-provisioner-install.sh
error: error validating "https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.65.0/release.yaml": error validating data: failed to download openapi: Get "http://localhost:8080/openapi/v2?     timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false
failed to install tekton pipeline

- Solution:
'''
microk8s config > ~/.kube/config
'''
