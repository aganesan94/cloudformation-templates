# Autoscaling with EKS

There are 3 types of autoscaling 

1. Horizontal POD Scaling
2. Cluster Auto Scaling
3. High performance autoscaling with Karpenter

## Why are there 2 Autoscaling frameworks provided by AWS?

https://kubesandclouds.com/index.php/2022/01/04/karpenter-vs-cluster-autoscaler/


---
## Horizontal Pod Scaling

* Scaling the pods based on a condition

### Pre-requisites

* Metrics server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Check Installation

```bash
kubectl get apiservice v1beta1.metrics.k8s.io -o json | jq '.status'
```

### Example


```bash
# Create a deploying 
kubectl create deployment php-apache --image=us.gcr.io/k8s-artifacts-prod/hpa-example

# Set requested cpu level to 200m
kubectl set resources deploy php-apache --requests=cpu=200m

# Export port to 80
kubectl expose deploy php-apache --port 80

# verify the pod is running
kubectl get pod -l app=php-

#Autoscale deployment
#The target average CPU utilization
#Desired number of pods is and max is 10
#If cpu percent goes above 50 new pods will be added
kubectl autoscale deployment php-apache \
    --cpu-percent=50 \
    --min=1 \
    --max=
    
# Generate load by logging into busybox
kubectl run -i --tty load-generator --image=busybox /bin/sh    

#Run the following in the bash prompt
while true; do wget -q -O - http://php-apache; done

#Watch the pods scale by opening ANOTHER 
kubectl get hpa -w

# IMPORTANT: Exit busy box with a ctrl+C on that terminal and exit
```

## Configure Autoscaler

Reference: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/

Preferred method of autoscaling is using the cluster-autoscaler which uses "Auto-Discovery"


### Get the capacity of the current autoscaler
---

The following command gives an idea of the default autoscaling set up of a cluster. In order to increase it we do the following

```bash
#Pass the appropriate profile and also the cluster.
AWS_PROFILE=cloudtel aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

### Increase the capacity of the current autoscaler
---

```bash
# Get the ASG name, pass the appropriate cluster name.
export AWS_PROFILE=cloudtel

export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].AutoScalingGroupName" --output text)

#Print to make sure you have the right ASG name
echo $ASG_NAME


# increase max capacity up to 4
aws autoscaling \
    update-auto-scaling-group \
    --auto-scaling-group-name ${ASG_NAME} \
    --min-size 3 \
    --desired-capacity 3 \
    --max-size 4

# Check new values
aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
```

## Set up necessary IAM roles for service accounts.

### IAM Roles for service accounts

Goal is for the pods to call the AWS APIs from the Worker Node.
With IAM roles for service accounts on Amazon EKS clusters, you can associate an IAM role with a Kubernetes service account. This service account can then provide AWS permissions to the containers in any pod that uses that service account. With this feature, you no longer need to provide extended permissions to the node IAM role so that pods on that node can call AWS APIs.

```bash
#Enabling IAM roles for service accounts on your cluster
eksctl utils associate-iam-oidc-provider \
    --cluster eksworkshop-eksctl \
    --approve
```

On executing the above you should see something similar

```bash
eksctl utils associate-iam-oidc-provider \
>     --cluster eksworkshop-eksctl \
>     --approve
2022-04-03 16:08:39 [ℹ]  eksctl version 0.90.0
2022-04-03 16:08:39 [ℹ]  using region us-east-1
2022-04-03 16:08:42 [ℹ]  will create IAM Open ID Connect provider for cluster "eksworkshop-eksctl" in "us-east-1"
2022-04-03 16:08:44 [✔]  created IAM Open ID Connect provider for cluster "eksworkshop-eksctl" in "us-east-1"
```

```bash

#Enabling IAM roles for service accounts on your cluster
AWS_PROFILE=cloudtel \
aws iam create-policy   \
  --policy-name k8s-asg-policy \
  --policy-document file://k8s-asg-policy.json
```

```bash
#Finally, create an IAM role for the cluster-autoscaler Service Account in the kube-system namespace.
AWS_PROFILE=cloudtel \
ACCOUNT_ID=716927497993 \
eksctl create iamserviceaccount \
    --name cluster-autoscaler \
    --namespace kube-system \
    --cluster eksworkshop-eksctl \
    --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/k8s-asg-policy" \
    --override-existing-serviceaccounts \
    --approve 
    
```


```bash
#Verify that the IAM Serviec account was associated to the 
# Note down the role arn
kubectl -n kube-system describe sa cluster-autoscaler
```

## Using the cluster autoscaler

Reference: https://docs.aws.amazon.com/eks/latest/userguide/autoscaling.html



```bash
#Download the file
curl -o cluster-autoscaler-autodiscover.yaml https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

#Apply the file
kubectl apply -f cluster-autoscaler-autodiscover.yaml


#To prevent CA from removing nodes where its own pod is running, we will add the cluster-autoscaler.kubernetes.io/safe-to-evict annotation to its deployment with the following command
kubectl -n kube-system \
    annotate deployment.apps/cluster-autoscaler \
    cluster-autoscaler.kubernetes.io/safe-to-evict="false"


```

```bash
# modify a few settings so there are no problems scaling to zero
kubectl -n kube-system edit deployment.apps/cluster-autoscaler

#Note the section Edit the cluster-autoscaler container command to replace <YOUR CLUSTER NAME> (including <>) with the name of your cluster, and add the 
#following options. --balance-similar-node-groups ensures that there is enough available compute across all availability zones. 
#--skip-nodes-with-system-pods=false ensures that there are no problems with scaling to zero.

    --balance-similar-node-groups

    --skip-nodes-with-system-pods=false

    spec:
      containers:
      - command
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/<YOUR CLUSTER NAME>
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false

```

```

# we need to retrieve the latest docker image available for our EKS version
export K8S_VERSION=$(kubectl version --short | grep 'Server Version:' | sed 's/[^0-9.]*\([0-9.]*\).*/\1/' | cut -d. -f1,2)
export AUTOSCALER_VERSION=$(curl -s "https://api.github.com/repos/kubernetes/autoscaler/releases" | grep '"tag_name":' | sed -s 's/.*-\([0-9][0-9\.]*\).*/\1/' | grep -m1 ${K8S_VERSION})

kubectl -n kube-system \
    set image deployment.apps/cluster-autoscaler \
    cluster-autoscaler=us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v${AUTOSCALER_VERSION}

kubectl -n kube-system logs -f deployment/cluster-autoscaler

```

### Let us install a pod and autoscale

```bash
# Deploy the app
kubectl apply -f cluster-autoscaler-nginx.yaml

# Verify the app is working
kubectl get deployment/nginx-to-scaleout

#Let us scale the pods
kubectl scale --replicas=10 deployment/nginx-to-scaleout

# Watch the cluster logs and simulataneously watch the pods and the cluster logs.
# You will see new nodes get added.
kubectl -n kube-system logs -f deployment/cluster-autoscaler
kubectl get pods -l app=nginx -o wide --watch
kubectl scale --replicas=10 deployment/nginx-to-scaleout
```

### Deleting all what we created


```bash
k delete deployment nginx-to-scaleout
kubectl delete hpa,svc php-apache
kubectl delete deployment php-apache
kubectl delete pod load-generator

k delete po load-generator
k delete -f cluster-autoscaler-autodiscover.yaml

AWS_PROFILE=cloudtel \
eksctl delete iamserviceaccount \
  --name cluster-autoscaler \
  --namespace kube-system \
  --cluster eksworkshop-eksctl \
  --wait


# Delete policy
export ACCOUNT_ID=716927497993

AWS_PROFILE=cloudtel \
aws iam delete-policy \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/k8s-asg-policy
  
#DELTE AUTOSCALING GROUP
export AWS_PROFILE=cloudtel
export ASG_NAME=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eksworkshop-eksctl']].AutoScalingGroupName" --output text)
aws autoscaling \
  update-auto-scaling-group \
  --auto-scaling-group-name ${ASG_NAME} \
  --min-size 1 \
  --desired-capacity 1 \
  --max-size 1  

# Delete metrics
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl delete ns metrics

#Check any other resources left to delete
kubectl get all,cm,secret,ing -A

# Delete dashboard
pkill -f 'kubectl proxy --port=8080'

# delete dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml
```