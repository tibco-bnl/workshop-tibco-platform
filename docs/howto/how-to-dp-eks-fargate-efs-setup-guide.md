
# EKS on Fargate with Amazon EFS - Setup Guide

## References

- [AWS EFS CSI Documentation](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-create-iam-resources)
- [Jenkins on EKS with EFS](https://www.youtube.com/watch?v=4MjbKDBkOdE)
- [AWS Blog: Deploying Jenkins on EKS with EFS](https://aws.amazon.com/blogs/storage/deploying-jenkins-on-amazon-eks-with-amazon-efs/)
- [GitHub Sample: EKS + EFS with Fargate](https://github.com/aws-samples/eks-efs-share-within-fargate)
- [AWS Blog: Stateful Workloads on EKS Fargate using EFS](https://aws.amazon.com/blogs/containers/running-stateful-workloads-with-amazon-eks-on-aws-fargate-using-amazon-efs/)

---

## EKS Cluster Setup Notes

- This guide assume the existance of an AWS EKS K8S cluster.
- **Do not deploy the EFS CSI driver add-on manually** – it is automatically deployed with Fargate.
- Use **both public and private subnets**. Public subnets allow access to the Kubernetes API from local machines.


---

## Environment Variables

```bash
AWS_DEFAULT_PROFILE=emea-use ## Based on local config in ~/.aws/config 
EKS_AWS_REGION=eu-west-1 
EKS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
EKS_EKS_CLUSTER=dp-on-eksfargate
EKS_DP_NAMESPACE=dp1
EKS_FARGATE_PROFILE=dp-on-fargate-profile
POD_EXECUTION_ROLE_ARN="arn:aws:iam::075021648303:role/EMEA_EKS-FARGATE-PODS"  ## role Provides access to other AWS service resources that are required to run Amazon EKS pods on AWS Fargates
EKS_FARGATE_NAMESPACES="namespace=default namespace=kube-system namespace=external-dns namespace=dp1" ## list of namespaces in which pods will be deployed using Fargate.
```

---

## Kubeconfig EKS Cluster Initialization

Update local kubeconfig to access the EKS cluster
```bash
aws eks update-kubeconfig --region $EKS_AWS_REGION --name $EKS_EKS_CLUSTER
```

Set VPC/CIDR details retrieved from EKS Cluster
```bash
EKS_VPC_ID=$(aws eks describe-cluster --name $EKS_EKS_CLUSTER --query "cluster.resourcesVpcConfig.vpcId" --region $EKS_AWS_REGION --output text)
echo "EKS_VPC_ID: $EKS_VPC_ID"
```
```bash
EKS_CIDR_BLOCK=$(aws ec2 describe-vpcs --vpc-ids $EKS_VPC_ID --query "Vpcs[].CidrBlock" --region $EKS_AWS_REGION --output text)
echo "EKS_CIDR_BLOCK: $EKS_CIDR_BLOCK"
```

---

## Create Fargate Profile

Manually retrieve the subnet-ids of the private subnets in the VPS related to the EKS cluster. add them in the variable EKS_VPC_PRIVATE_SUBNETIDS.

```bash
EKS_VPC_PRIVATE_SUBNETIDS="subnet-123Example subnet-456Example"

aws eks create-fargate-profile     \
   --cluster-name $EKS_EKS_CLUSTER \
   --fargate-profile-name $EKS_FARGATE_PROFILE  \
   --pod-execution-role-arn $POD_EXECUTION_ROLE_ARN  \
   --subnets $EKS_VPC_PRIVATE_SUBNETIDS
   --selectors $EKS_FARGATE_NAMESPACES
```

Wait for the fargate profile to become Active in the EKS cluster. 
```
aws eks describe-fargate-profile --cluster-name $EKS_EKS_CLUSTER  --fargate-profile-name $EKS_FARGATE_PROFILE
```


### Restart System Deployments on Fargate
In order to retrigger deployment of the core K8S service execute below command. This will start using fargate as deployment target.

```bash
kubectl rollout restart -n kube-system deployment coredns
kubectl rollout restart -n kube-system deployment metrics-server
kubectl rollout restart -n external-dns deployment external-dns
```

---

## EFS Setup
This section describes the setup of the persistent storage based on EFS. EFS is the required type of storage on Fargate.
Only static assigned storage is permitted on Fargate.

### Create EFS File System

```bash
EKS_EFS_FS_ID=$(aws efs create-file-system   --creation-token eks-on-fargate   --encrypted   --performance-mode generalPurpose   --throughput-mode bursting   --tags Key=Name,Value=dpVolume   --region $EKS_AWS_REGION   --query "FileSystemId" --output text)
echo "EKS_EFS_FS_ID: $EKS_EFS_FS_ID"
```

### Create EFS Access Point

```bash
EKS_EFS_AP=$(aws efs create-access-point   --file-system-id $EKS_EFS_FS_ID   --posix-user Uid=0,Gid=0   --root-directory "Path=/"   --region $EKS_AWS_REGION   --tags Key=Name,Value=tp-ap   --query 'AccessPointId' --output text)
echo "EKS_EFS_AP= $EKS_EFS_AP"

```

### Create Security Group and Add Ingress
The EKS cluster resources require access to the fargate services volumes. For this port 2049 is allowed in the vpc ingress.

```bash
EKS_EFS_SG_ID=$(aws ec2 create-security-group   --description eks-on-fargate-ingress   --group-name eks-on-fargate   --vpc-id $EKS_VPC_ID   --region $EKS_AWS_REGION   --query 'GroupId' --output text)
```
```bash
aws ec2 authorize-security-group-ingress   --group-id $EKS_EFS_SG_ID   --protocol tcp   --port 2049   --cidr $EKS_CIDR_BLOCK

aws ec2 describe-security-groups --group-ids $EKS_EFS_SG_ID
```

### Create Mount Targets

An EFS mount target is an NFSv4 endpoint that allows EC2 instances or Fargate tasks within a VPC to access the EFS file system.

```bash
for subnet in $(aws eks describe-fargate-profile   --cluster-name $EKS_EKS_CLUSTER   --fargate-profile-name $EKS_FARGATE_PROFILE   --region $EKS_AWS_REGION   --query "fargateProfile.subnets" --output text); do
    aws efs create-mount-target       --file-system-id $EKS_EFS_FS_ID       --subnet-id $subnet       --security-group $EKS_EFS_SG_ID       --region $EKS_AWS_REGION
done

aws efs describe-mount-targets --file-system-id $EKS_EFS_FS_ID
```

---

## Dataplane Registration

Register the new dataplane in the Control Plane using namespace: `$EKS_DP_NAMESPACE`
1. Helm repo configuration
2. Namespace creation
3. ServiceAccount creation
4. Cluster Registration

Wait for dataplane to appear green and connected

---

## Kubernetes Storage Configuration

### Create Storage Class

```bash
echo "
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
mountOptions:
  - tls
reclaimPolicy: Retain
volumeBindingMode: Immediate
" | kubectl apply -f -
```

### Create Persistent Volume

```bash
echo "
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv-am
spec:
  capacity:
    storage: 50Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: $EKS_EFS_FS_ID::$EKS_EFS_AP
" | kubectl apply -f -
```
If the PV already exists and following step (capability provisioning) is failing it will help to first delete the existing PV, recreated with above command and then continue.
---

## Provision Capabiity

Provision a capability (Flogo or BWCE) which require persistent storage.
Use 'efs-sc' as storage class

---
## The below section may not be required if artifactmanager pod is going into a running state after a while.

### Reset Persistent Volume claim

Once artifactmanager is deployed (it will never run) execute:
```bash
kubectl scale deploy -n dp1 --replicas=0 artifactmanager
kubectl delete pvc artifactmanager-integration -n dp1
```
This will delete the existing PVC created by the provisioning of the capability. 
(the PVC has as accessMode: ReadWriteMany, which is not allowed by the EFS driver)


### Create Persistent Volume Claim
```
echo "
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: artifactmanager-integration
  namespace: $EKS_DP_NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: efs-sc
  resources:
    requests:
      storage: 10Gi
" | kubectl apply -f -
```

### Final Deployment Steps

```bash
kubectl scale deploy -n dp1 --replicas=1 artifactmanager
kubectl rollout restart -n dp1 deployment flogoprovisioner
```
