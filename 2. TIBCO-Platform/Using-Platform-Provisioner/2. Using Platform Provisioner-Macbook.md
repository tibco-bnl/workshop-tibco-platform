
# Prerequisites

Ensure you have the following tools installed:
- Docker Desktop or Podman
- Kubernetes: Docker Desktop with Kubernetes enabled, or MicroK8s, or Minikube
- kubectl
- git

# Build the platform provisioner docker image

Follow these steps to run the script:

1. **Install dependencies**
    ```sh
    brew install yq
    ```

2. **Clone the platform-provisioner repository:**
    ```sh
    mkdir -p ~/git
    cd ~/git
    git clone https://github.com/TIBCOSoftware/platform-provisioner.git
    ```

3. **Navigate to the platform-provisioner directory:**
    ```sh
    cd ~/git/platform-provisioner
    ```

4. **Build the Platform Provisioner Docker image:**
    ```sh
    cd docker
    ./build.sh
    ```

5. ** (Optional) Login to Docker (if required):**
    ```sh
    #docker login -u "<< dockerhub username >>" -p "$DOCKER_PASSWORD" docker.io
    ```

6. **Tag the docker image and (Optionally) push the Docker image to Docker Hub:**

    To tag and push the Docker image to Docker Hub, follow these steps:

    1. **Tag the Docker image:**
        ```sh
        docker image tag platform-provisioner:latest <dockerhub-username>/platform-provisioner:v1
        ```

    2. **(Optionally) Push the Docker image:**
        ```sh
        docker push <dockerhub-username>/platform-provisioner:v1
        ```

    Replace `<dockerhub-username>` with your Docker Hub username.

7. **Verify the Docker image:**
    ```sh
    docker images | grep platform-provisioner
    ```

# Running Platform Recipes to Create TIBCO Platform (CP, DP) - Local K8s

Set the following environment variables and run the platform provisioner install script to execute the desired recipe and pipeline:
- `PIPELINE_NAME`
- `PIPELINE_INPUT_RECIPE`

8. **Use the appropriate Kubernetes context:**
    - For Docker Desktop:
        ```sh
        kubectl config use-context docker-desktop
        ```
    - For MicroK8s:
        ```sh
        alias kubectl='microk8s kubectl'
        microk8s start
        ```
    - For Minikube:
        ```sh
        minikube start
        kubectl config use-context minikube
        ```

9. **Install Tekton Pipeline and access the dashboard:**
    ```sh
    export PIPELINE_SKIP_TEKTON_DASHBOARD=false
    cd ..
    ./dev/platform-provisioner-install.sh
    ```

    **Wait for Tekton Pipelines to be ready:**
    ```sh
    echo "Waiting for Tekton Pipelines to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-controller -n tekton-pipelines
    kubectl wait --for=condition=available --timeout=600s deployment/tekton-pipelines-webhook -n tekton-pipelines
    ```

    **Port forward and open Tekton Dashboard:**
    ```sh
    echo "Port forwarding Tekton Dashboard..."
    kubectl -n tekton-pipelines port-forward service/tekton-dashboard 9097:9097 &
    echo "Open Tekton Dashboard at http://localhost:9097/#/about"
    ```

10. **Run a test task to check everything is fine (optional):**
    ```sh
    export PIPELINE_NAME="generic-runner"
    export PIPELINE_INPUT_RECIPE="$(pwd)/docs/recipes/tests/test-local.yaml"
    # Note: Verify and review the test-local.yaml file. If needed, make a copy and edit it before use.
    ./dev/platform-provisioner-pipelinerun.sh
    ```

    **Wait for the pipeline run to complete:**
    ```sh
    echo "Waiting for generic-runner pipeline run to complete..."
    kubectl wait --for=condition=Succeeded --timeout=600s pipelinerun/generic-runner-on-prem-6 -n tekton-tasks
    ```

11. **Install TIBCO Platform CP: Run helm-install pipeline:**
    ```sh
    export PIPELINE_NAME="helm-install"
    export PIPELINE_INPUT_RECIPE="$(pwd)/docs/recipes/tp-base/tp-base-on-prem.yaml"
    # Note: Verify and review the tp-base-on-prem.yaml file. If needed, make a copy and edit it before use.
    ./dev/platform-provisioner-pipelinerun.sh
    ```

    **Wait for the pipeline run to complete:**
    ```sh
    echo "Waiting for helm-install pipeline run to complete..."
    kubectl wait --for=condition=Succeeded --timeout=600s pipelinerun/helm-install-on-prem-27 -n tekton-tasks
    ```

