# EKS Workshop

Note: Ensure all pre-requisites in the README.md is ready.

The following need to be set before running workshop

## One time set up
```bash
cd ~/picto/git/eks
git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git
```

```bash
export AWS_PROFILE=<profile>
aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
```

```bash
export AWS_PROFILE=cloudtel
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" 
```

Add below to values to ~/.bashrc and source the file

```bash
export LBC_VERSION="v2.4.0"
export MASTER_ARN=${MASTER_ARN}
```




## Creating the cluster

Note: After adding this type "EOF" to get out of the prompt

```bash
cat << EOF > eksworkshop.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: eksworkshop-eksctl
  region: "us-east-1"
  version: "1.21"

availabilityZones: ["us-east-1a", "us-east-1b", "us-east-1c"]

managedNodeGroups:
- name: nodegroup
  desiredCapacity: 3
  instanceType: t3.medium
  ssh:
    enableSsm: true

# To enable all of the control plane logs, uncomment below:
# cloudWatch:
#  clusterLogging:
#    enableTypes: ["*"]

secretsEncryption:
  keyARN: ${MASTER_ARN}
```
## Ensure the cluster is working

```bash
$ kubectl describe configmap -n kube-system aws-auth
Name:         aws-auth
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
mapRoles:
----
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::716927497993:role/eksctl-eksworkshop-eksctl-nodegro-NodeInstanceRole-8W7SRYM41VAY
  username: system:node:{{EC2PrivateDNSName}}

Events:  <none>
```

## Installing the kubernetes dashboard

Reference: https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
```

## Accessing the dashboard 

Reference: https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html
### Step 1: Created an admin-service account

```bash
cat << EOF > eks-admin-service-account.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
```

### Step 2: Get an auth token

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```

Copy the token

### Step 3:  Set up a proxy

```
kubectl proxy
```

### Step 4: Access the dashboard

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login


### Step 5: Kill the dashboard if you arent using it

```bash
# kill proxy
pkill -f 'kubectl proxy'

# delete dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
```


## Deploying the different microservices


```bash
 #cd into the directory
 cd ecsdemo-nodejs/


 kubectl apply -f kubernetes/deployment.yaml
 kubectl apply -f kubernetes/service.yaml


 k get deployments
 k get po
 k get svc
```

```bash
 #cd into the directory
 cd ecsdemo-crystal/


 kubectl apply -f kubernetes/deployment.yaml
 kubectl apply -f kubernetes/service.yaml


 k get deployments
 k get po
 k get svc
```

```bash
 #cd into the directory
 cd ecsdemo-frontend/


 kubectl apply -f kubernetes/deployment.yaml
 kubectl apply -f kubernetes/service.yaml


 k get deployments
 k get po
 k get svc
```

## Check if you are allowed to provision a load balancer

This should return some response.

```
AWS_PROFILE=cloudtel \
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || \
aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"
```

### Troubleshooting

if pods do not come up refer to the node instance type and max pods supported 

https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt

https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/

https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/


