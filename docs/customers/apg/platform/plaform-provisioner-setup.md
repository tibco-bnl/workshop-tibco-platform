# TIBCO Platform setup with the Platform Provisioner (on-prem, WSL2 + minikube)

This is a short, opinionated guide to install the TIBCO Platform on a local
on-prem Kubernetes cluster using the
[Platform Provisioner headless on-prem recipe](https://github.com/TIBCOSoftware/platform-provisioner/tree/main/docs/recipes/k8s/on-prem).

The setup below was validated on **Windows with WSL2 (Ubuntu) + Docker + minikube**.

---

## 1. Prerequisites

Install the following inside your WSL2 Ubuntu shell:

- Docker (Docker Desktop with WSL2 integration, or `docker` inside WSL)
- `kubectl`
- `helm`
- `yq` (v4.40+)
- `mkcert`
- `zip`
- `minikube`

Verify:

```bash
docker version
kubectl version --client
helm version
yq --version
mkcert -version
minikube version
```

You also need:

- A TIBCO container registry account (JFrog: `csgprduswrepoedge.jfrog.io`)
- A TIBCO Platform license file (`license.bin`) downloaded from the
  [TIBCO support portal](https://ui.licensingprod-int.tibco.com/ui)

---

## 2. Start the minikube cluster

From your WSL2 shell:

```bash
minikube start \
  --memory 28672 \
  --disk-size "40g" \
  --driver=docker \
  --addons storage-provisioner
```

> Recommended host sizing: at least 24 vCPU / 28 GB RAM allocated to WSL2
> (configure via `%UserProfile%\.wslconfig`). With this you can run the Control
> Plane plus a Data Plane with Flogo, BWCE, messaging and TIBCO Hub.

Confirm the cluster is reachable:

```bash
kubectl get nodes
```

---

## 3. Configure environment variables

The headless installer is driven by `GUI_*` and `TP_*` environment variables.
Export them in your shell (or put them in a sourced `.env` file):

```bash
# Cluster + ingress
export TP_K8S_CLUSTER_TYPE_CODE=4          # 4 = minikube
export TP_K8S_INGRESS_TYPE_CODE=2          # 2 = traefik
export TP_AUTOMATION_SCRIPT_OPTIONS=1      # 1 = deploy all
export TP_TOP_DOMAIN="dev.localhost"

# TIBCO container registry
export GUI_CP_CONTAINER_REGISTRY=csgprduswrepoedge.jfrog.io
export GUI_CP_CONTAINER_REGISTRY_REPOSITORY=tibco-platform-docker-prod
export GUI_CP_CONTAINER_REGISTRY_USERNAME="<your-jfrog-user>"
export GUI_CP_CONTAINER_REGISTRY_PASSWORD="<your-jfrog-token>"

# License file (will be zipped + base64-encoded by the installer)
export GUI_TP_LICENSE_FILE_PATH="$HOME/license.bin"
```

The default domain `dev.localhost` resolves to `127.0.0.1`, so the platform
will be reachable at:

- `https://admin.cp1-my.dev.localhost` — Control Plane admin console
- `https://cp-sub1.cp1-my.dev.localhost` — Control Plane subscription console
- `https://mail.dev.localhost` — self-hosted mail (activation emails)

A self-signed TLS certificate is generated automatically with `mkcert` when
`GUI_TP_TLS_CERT` / `GUI_TP_TLS_KEY` are not provided.

---

## 4. Run the headless installer

Download and run the helper script. It runs inside a Docker container and uses
your local kubeconfig to install the platform.

```bash
curl -sSL -O https://raw.githubusercontent.com/TIBCOSoftware/platform-provisioner/main/docs/recipes/k8s/on-prem/scripts/headless/tp-install-on-prem.sh
chmod +x tp-install-on-prem.sh
./tp-install-on-prem.sh
```

> Expect the full installation to take **between 30 and 60 minutes**, depending
> on the CPU, memory and network speed of the target machine.

With the environment variables above set, the script runs non-interactively and
will:

1. Download the recipes into the current directory (`01-tp-on-prem.yaml`,
   `02-tp-cp-on-prem.yaml`, `05-tp-auto-deploy-dp.yaml`,
   `06-tp-o11y-stack.yaml`, …).
2. Install third-party tools (Traefik ingress, cert-manager, metrics-server,
   PostgreSQL).
3. Install the TIBCO Control Plane.
4. Create a subscription and deploy a Data Plane.
5. Deploy the enabled capabilities (BWCE, Flogo by default).

> Tip: to only generate the recipes (and tweak them before deploying), set
> `export TP_SKIP_DEPLOY=true` and then run `./run.sh 1` later.

---

## 5. Expose the ingress to the Windows host

minikube runs inside WSL2, so the Traefik ingress is not directly reachable
from the Windows host. Forward the ingress ports from WSL with `kubectl`
(keep this command running in its own terminal).

Binding to ports 80 and 443 requires root, so first make your kubeconfig
available to the `root` user:

```bash
sudo mkdir -p /root/.kube
sudo cp /home/${USER}/.kube/config /root/.kube/config
```

Then start the port-forward as root:

```bash
sudo kubectl port-forward -n ingress-system --address 0.0.0.0 \
  service/traefik 80:web 443:websecure
```

On recent Windows builds, `localhost` is automatically forwarded from the
Windows host into WSL2, so you can open the Control Plane URLs
(`https://admin.cp1-my.dev.localhost`, …) directly in your Windows browser.

If your Windows hosts file does not yet resolve the `*.dev.localhost` names,
add the following entries to `C:\Windows\System32\drivers\etc\hosts`:

```text
127.0.0.1   admin.cp1-my.dev.localhost
127.0.0.1   cp-sub1.cp1-my.dev.localhost
127.0.0.1   cp-sub1.cp1-tunnel.dev.localhost
127.0.0.1   mail.dev.localhost
```

---

## 6. Verify the installation

```bash
kubectl get pods -A
```

Open the Control Plane admin console:

<https://admin.cp1-my.dev.localhost>

Activation emails are delivered to the local mail server at
<https://mail.dev.localhost>.

Deployment reports are written to `./report/`.

---

## 7. Re-running / cleanup

- Re-run a single recipe: `./run.sh <n>` (e.g. `./run.sh 8` for the BW5 stack).
- Stop the port-forward: press `Ctrl+C` in the terminal running it.
- Tear down the cluster: `minikube delete`.

---

## References

- Platform Provisioner on-prem recipe:
  <https://github.com/TIBCOSoftware/platform-provisioner/tree/main/docs/recipes/k8s/on-prem>
- Platform Provisioner repository:
  <https://github.com/TIBCOSoftware/platform-provisioner>
