> Open WSL Ubuntu

> install git, kubectl

> create directory ~/projects/platform-dev

mkdir -p ~/projects/platform-dev
cd ~/projects/platform-dev


> clone git projects 
git clone  https://github.com/mcommiss-tibco/platform-provisioner.git
git clone  https://github.com/tibco-bnl/workshop-tibco-platform

Platform-provisioner is temporary from mcommiss user which includes the recipes for local... to be moved to tibco-bnl repo

> open ~/projects/platform-dev in vs-code

> open ~/projects/platform-dev/workshop-tibco-platform/scripts/run_platform_provisioner.sh

update PP_GIT_DIR with full value of project location, i.e. '/home/marco/projects/platform-dev'

> open ~/projects/platform-dev/platform-provisioner/docs/recipes/tp-base/tp-base-on-prem-https-docker-desktop.yaml

update the values of guiEnv attributes:
GUI_TP_TLS_CERT: 
GUI_TP_TLS_KEY: 

Values can be found in https://docs.google.com/document/d/1f39d0_L6iRpEPjJggYFJrL3oVAtDyPdVbOnjmzU7E0E/edit?tab=t.l6dihjhx60qc#heading=h.8ir76m4dmdxu

> open ~/projects/platform-dev/platform-provisioner/docs/recipes/controlplane/tp-cp-docker-desktop.yaml
update the values of guiEnv attribute:
GUI_CP_CONTAINER_REGISTRY_PASSWORD

Value can be found in https://docs.google.com/document/d/1f39d0_L6iRpEPjJggYFJrL3oVAtDyPdVbOnjmzU7E0E/edit?tab=t.l6dihjhx60qc#heading=h.4i48lhw213n

Save all updated files.


> run installer
cd ~/projects/platform-dev/workshop-tibco-platform/scripts
./run_platform_provisioner.sh

