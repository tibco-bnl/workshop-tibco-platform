# How to install seperate platform components

Instead of installing all platform components in one go, it is possible to install seperate components.


## Install observability

Run the following commands

```bash
# current directory from which
WORKSHOP_SCRIPT_DIR=~/projects/platform-dev 
WORKSHOP_BASE_DIR=$WORKSHOP_SCRIPT_DIR/..

# Clone the platform-provisioner repository
PP_GIT_DIR=~/git/tmp
PP_DIR=$PP_GIT_DIR/platform-provisioner

SECRETS_FILE=$WORKSHOP_BASE_DIR/scripts/secrets.env
export $(grep -v '^#' $SECRETS_FILE | xargs)

mkdir -p $PP_GIT_DIR
cd $PP_GIT_DIR

if [ ! -d "$PP_DIR" ]; then
    git clone https://github.com/TIBCOSoftware/platform-provisioner.git
    #git clone https://github.com/kulbhushan-tibco/platform-provisioner.git
    echo ""

    ##Following branch has most of the workarounds
    cd platform-provisioner
    #git checkout kul-pp
    echo ""

else
    cd $PP_DIR
    echo "Platform-provisioner directory already exists. Stashing your changes and applying them after pulling from remote..."
    echo ""
    git add .
    git stash
    echo ""
    git fetch --all --prune
    echo ""
    git pull
    echo ""
    git stash apply
    echo ""

fi
```
