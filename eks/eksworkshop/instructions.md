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

# Check if the context has been set correctly
kubectl config get-contexts


# Check if cluster is working as expected and you are able to access it.
kubectl describe configmap -n kube-system aws-auth
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

```bash
kubectl apply -f eks-admin-service-account.yaml
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

*Note*


The service.yaml for the frontend services is as below. Notice the type parameter
type: LoadBalancer

This basically creates a classic loadbalancer for received requests in AWS.

```bash
apiVersion: v1
kind: Service
metadata:
  name: ecsdemo-frontend
spec:
  selector:
    app: ecsdemo-frontend
  type: LoadBalancer
  ports:
   -  protocol: TCP
      port: 80
      targetPort: 3000
```
The service.yaml for the backend services is as below. Notice the type parameter
type: ClusterIP. This is the default

```bash
apiVersion: v1
kind: Service
metadata:
  name: ecsdemo-nodejs
spec:
  selector:
    app: ecsdemo-nodejs
  ports:
   -  protocol: TCP
      port: 80
      targetPort: 3000
```

## Check if you are allowed to provision a load balancer

This should return some response.

```
AWS_PROFILE=cloudtel \
aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || \
aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"
```

## Access the microservice

The following command should give the URL for the Loadbalancer which can be used to access the application.

```bash
kubectl get service ecsdemo-frontend -o wide
```

```bash
ELB=$(kubectl get service ecsdemo-frontend -o json | jq -r '.status.loadBalancer.ingress[].hostname')

curl -m3 -v $ELB
```

## Checking the nodes where the pods are deployed to

```bash
k get po -o wide
NAME                                READY   STATUS    RESTARTS   AGE   IP               NODE                            NOMINATED NODE   READINESS GATES
ecsdemo-crystal-856c46f686-vmpnd    1/1     Running   0          43m   192.168.69.153   ip-192-168-64-64.ec2.internal   <none>           <none>
ecsdemo-frontend-679545f5b5-9lm4g   1/1     Running   0          35m   192.168.43.11    ip-192-168-58-77.ec2.internal   <none>           <none>
ecsdemo-nodejs-99fbbf9-xx79v        1/1     Running   0          44m   192.168.18.7     ip-192-168-31-95.ec2.internal   <none>           <none>
```


## Scaling the services

```bash

# Scaling backend
kubectl scale deployment ecsdemo-nodejs --replicas=3
kubectl scale deployment ecsdemo-crystal --replicas=3

# Verify if deployments have scaled.
kubectl get deployments

# Scaling frontend
kubectl scale deployment ecsdemo-frontend --replicas=3
kubectl get deployments
```



## Deleting the services

cd into each directory

```
kubectl delete -f kubernetes/service.yaml
kubectl delete -f kubernetes/deployment.yaml
```




## Using Helm

Reference: https://helm.sh/docs/intro/install/

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

### Verify installation
```
helm version --short
```
If at all you see an error stating "WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: "
execute the following command

```bash
chmod go-r ~/.kube/config
```

### Add helm stable and update

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo update
helm search repo stable
```

### Search the helm repo
This should list all the charts availabe in helm
Reference: /

```bash
helm search repo
```

### Locate and install nginx

```bash
helm search repo nginx
```
Unfortunately the above helm is not a standlone nginx server hence we move to bitnami

```bash
# Add bitnamic repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for bitnami
helm search repo bitnami/nginx


### Dryrun a chart before installing it
helm install --dry-run --debug abc bitnami/nginx


#Install nginx
helm install <somename> bitnami/nginx
Ex: helm install nginx-tester bitnami/nginx
```

*Output of installation is as follows*

```bash
helm install nginx-tester bitnami/nginx
NAME: nginx-tester
LAST DEPLOYED: Sun Apr  3 13:55:04 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 9.9.8
APP VERSION: 1.21.6

** Please be patient while the chart is being deployed **

NGINX can be accessed through the following DNS name from within your cluster:

    nginx-tester.default.svc.cluster.local (port 80)

To access NGINX from outside the cluster, follow the steps below:

1. Get the NGINX URL by running these commands:

  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        Watch the status with: 'kubectl get svc --namespace default -w nginx-tester'

    export SERVICE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].port}" services nginx-tester)
    export SERVICE_IP=$(kubectl get svc --namespace default nginx-tester -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "http://${SERVICE_IP}:${SERVICE_PORT}"

```

### Verify if the deployment is running

```bash
k get deployment
```

### Check if load balancer has been provisioned

```bash
k get svc -o wide
```

This should provide an  as follows with the ELB Details

```bash
k get svc -o wide
NAME           TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)        AGE     SELECTOR
kubernetes     ClusterIP      10.100.0.1       <none>                                                                   443/TCP        5h40m   <none>
nginx-tester   LoadBalancer   10.100.100.152   a2bd6d0d98a4e4a6794376cc7d40325a-852966650.us-east-1.elb.amazonaws.com   80:31405/TCP   5m57s   app.kubernetes.io/instance=nginx-tester,app.kubernetes.io/name=nginx

```

If you just need the load balancer info try the following command

```bash
kubectl get svc <service-name> -o jsonpath="{.status.loadBalancer.ingress[*].hostname}"; echo
```

### List and uninstall the desired helm services

```bash
helm uninstall <name>

#Ex
helm uninstall nginx-tester
```

### Other commands that may be helpful

```bash
#If you make changes to the chart and wish to upgrade the deployment
helm upgrade <helm-name> <directory of the chart>

# Get the last deployed timestamp for a particular deployment
helm status <helm-name>

# List the previous history of deployment
helm history <helm-name>

# Roll back to version 1
helm rollback <helm-name> 1
```


# Troubleshooting

if pods do not come up refer to the node instance type and max pods supported 

https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt

https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/

https://aws.amazon.com/blogs/containers/amazon-vpc-cni-increases-pods-per-node-limits/


