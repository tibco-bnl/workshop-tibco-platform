 Open WSL Ubuntu
 
 
 #### Install minikube
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
```
#### Install required software

```
sudo snap install yq
sudo snap install helm --classic
sudo snap install kubectl --classic
```

#### Install docker engine

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

```

```
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

```
sudo usermod -aG docker $USER
newgrp docker
```


C### create directory ~/projects/platform-dev
```
mkdir -p ~/projects/platform-dev
cd ~/projects/platform-dev
```

#### clone git projects 
git clone  https://github.com/tibco-bnl/workshop-tibco-platform

Platform-provisioner is temporary from mcommiss user which includes the recipes for local... to be moved to tibco-bnl repo

### open ~/projects/platform-dev in vs-code

```
cd ~/projects/platform-dev/workshop-tibco-platform
git switch tp_on_minikube
code .
```

### update secrets file

```
cd ~/projects/platform-dev/workshop-tibco-platform/scripts
cp secrets.envEmpty secrets.env
```

Open file ~/projects/platform-dev/workshop-tibco-platform/scripts/secrets.env in an editor.
Replace the values of all the variables with the value 'TO_BE_REPLACED'.
* TLS_CERT
* TLS_KEY
* CONTAINER_REGISTRY_PASSWORD 

Values can be found in document https://docs.google.com/document/d/1f39d0_L6iRpEPjJggYFJrL3oVAtDyPdVbOnjmzU7E0E/edit?tab=t.l6dihjhx60qc#heading=h.8ir76m4dmdxu

#### Execute platform install script


```
cd ~/projects/platform-dev/workshop-tibco-platform/scripts
./run_platform_provisioner.sh
```

