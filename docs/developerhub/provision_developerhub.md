# Provision Developer Hub


## Requirements
To provision developer hub the following aspects are required:

* Active dataplane on a controlplane
* User with sufficient right on the dataplane to deploy capabilities
* command line access to update the core DNS configuration

## Provisioning

The provisioning of the developer hub involves the following steps:

1) update Core DNS with the developer hub dns entry
2) Provision Developer hub capability in dataplane via ui
3) Configure github integration
<br><br>

---
## Step 1: update Core DNS with the developer hub dns entry

Retrieve the IP-address of the minikube node

```
minikube node list
```
![alt text](images/image-1.png)


Open coreDNS configuration for editting

```
kubectl -n kube-system edit configmaps coredns
```

![alt text](images/image_dns1.png)

Addin the host section the IP-Address found above with the dns name of the developerhub:

(example)
```
192.168.49.2 devhub.benelux.cp1-my.localhost.dataplanes.pro
```

![alt text](images/image_dns2.png)


save and exit the configmap
```
[esc]:q
```
---
## Step2: Provision Developer hub capability in dataplane via ui


Open the Control plan UI and access the dataplane

![alt text](images/image_dp.png)

Click Provision a capability

Start Provision TIBCO Developer Hub

Add storage. Storage class name need to be in line with the k8s platform (minikube=standard)

![alt text](images/addStorage.png)

Add ingress Controller.

![alt text](images/addIngress.png)


![alt text](images/addResources.png)


![alt text](images/configuration.png)


Don't provide customer configuration and confirm.


![alt text](images/wait.png)

---
## 3 Configure github integration

The developer hub needs to be able to create/update github repositories while executing templates, for instance to create a flogo project.

### 3.1 Create a github Personal Access Token

The personal access token (PAT) is a part of the app-config associated with your application. Ensure the below structure is added in your custom config file while provisioning.

The above image shows the ${GITHUB_TOKEN} as an environment variable that gets replaced by an actual token value. The value gets replaced with the GITHUB_TOKEN variable that comes from the Kubernetes Secrets Object.

Permissions for GitHub Personal Access Token

In your GitHub account, go to Settings, and click Developer Settings. From the personal access token, select the fine-grained tokens. Here, you can select on whose behalf the token is being generated. Select your organization that you want to link with the TIBCO Developer Hub, and complete the further steps.

A fine-grained token helps to configure restricted access to your organization and its data. For example, you can configure read or write permissions to repositories, view administrative data, and manage members in a repository. 

The following is the minimum set of permissions required to integrate the TIBCO Developer Hub with GitHub. This helps you use a complete range of TIBCO Developer Hub features.
Organization Permissions

#### Organization Permissions
| | | | 
|-|-|-| 
|Permission| 	Type| 	Usage| 
|Administration| 	Read & Write|  	Admin access to an organization
|Custom Organization Roles| 	Read & Write| 	Create, edit, delete, and list custom organization roles. View system organization roles.|
|Custom Repository Roles| 	Read & Write| 	Create, edit, delete, and list the custom repository roles.|
|Events| 	Read Only| 	View events triggered by an activity in an organization."|
|Members| 	Read & Write| 	Organization members and teams. Fetch or change members and teams in an organization.|
|Organization Codespaces| 	Read & Write |	Manage Codespaces for an organization.|
|Variables |	Read & Write| 	Manage Actions organization variables.|

#### Repository Permissions
| | | | 
|-|-|-| 
|Permission| 	Type| 	Usage| 
|Actions |	Read & Write|Manage Actions repository variables.| 	 
|Administration| 	Read & Write| 	Required for repository - creation, deletion, updation, settings, teams, and collaborators.|
|Codespaces |	Read & Write| 	GitHub Codespaces is an instant, cloud-based development environment that uses a container to provide you with common languages, tools, and utilities for development.|
|Commit Statuses |	Read & Write |	To fetch and make commits to a repository.|
|Contents| 	Read & Write |	Repository contents, commits, branches, downloads, releases, and merges.|
|Environments |	Read & Write| 	Manage repository environments.|
|Metadata| 	Read & Write| 	Search repositories, list collaborators, and access repository metadata.|
|Pull Requests| 	Read & Write| 	Pull requests and related comments, assignees, labels, milestones, and merges.|


### 3.2 Encode the PAT to base64

The created PAT needs to be base64 encoded.

```
echo '<generated PAT>' | base64
```

The result will be used in the kubernetes secret to be created in the next step

### 3.3 Create kubernetes secret with encoded PAT

Create a YAML config file (tib-hub-secrets.yaml) by including the below structure and replace the <encoded token> with base64 encoded PAT from the previous step

```apiVersion: v1
kind: Secret
metadata:
  name: tibco-hub-secrets
type: Opaque
data:
  # replace with your values
  GITHUB_TOKEN: <encoded token>
```

Create the secret in the dataplane where the develop hub is provisioned.

```
kubectl apply -f tib-hub-secrets.yaml -n <REPLACE-WITH-YOUR-DATAPLANE-NAMESPACE>
```

### 3.4 Configure the github integration in the developer hub configuration

In CP UI follow these steps:

* Goto Dataplane
* Click on Developer Hub capability
* Click Update Configuration

Add below configuration to the end of the existing configuration
```
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
```

In the Kubernetes Secret Object field enter 'tibco-hub-secrets'
<br><br>

![alt text](images/devhub_github.png)

* Update Configuration

The configuration will now be updated.

---
