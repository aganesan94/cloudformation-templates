# Elastic Kubernetes Service

## Pre-requisites

* EKSCTL (https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
  * Install eksctl, and other dependencies such aws-iam


## Using eksctl

#### Use case-1 

Note: Creates all the infra required including VPCs

```bash
eksctl create cluster
--name <cluster-name> \
--region <region-name> \
--version <kubectl-version> \
--nodegroup-name-name <name> \
--node-type <ec2instance-type>
--nodes <no-of-nodes>
```

```
AWS_PROFILE=<profile-name> eksctl create cluster --name dev-test --dry-run
```

###### Deleting a cluster
```
eksctl delete cluster --name <cluster-name>
```

##### Examples

###### Quicksetup

Note: This sets up the kubeconfig automatically
```
AWS_PROFILE=cloudtel \
eksctl create cluster \
--name dev-eks \
--region us-east-1 \
--version  1.21 \
--nodegroup-name dev-eks-node \
--node-type t2.micro \
--nodes 2 \
--tags environment=dev \
```

###### Writing a to a new kubeconfig file

Note: This sets up new kubeconfig, can be set up this way
so other developers can use it.

```
AWS_PROFILE=cloudtel \
eksctl create cluster \
--name dev-eks \
--region us-east-1 \
--version  1.21 \
--nodegroup-name dev-eks-node \
--node-type t2.micro \
--nodes 2 \
--kubeconfig /home/cloudtel/picto/git/cloudformation-templates/eks/dev-eks.config \
--tags environment=dev
```
In this case what we will need to do is that we need to merge to the kube config files for use by other developers

Back up your current profile
```bash
cp ~/.kube/config ~/.kube/backup
```

```bash
#back up existing kubeconfig and write again
cp $HOME/.kube/config $HOME/.kube/config.backup.$(date +%Y-%m-%d.%H:%M:%S)

#Merge existing kube config
KUBECONFIG=$HOME/.kube/config:/home/cloudtel/picto/git/cloudformation-templates/eks/dev-eks.config: kubectl config view --merge --flatten > \
~/.kube/merged_kubeconfig && mv ~/.kube/merged_kubeconfig ~/.kube/config

#View the config to make sure all is well
cat ~/.kube/config
```



###### Deleting a cluster

Note: This removes the kubeconfig automatically
```
AWS_PROFILE=cloudtel \
eksctl delete cluster --name dev-eks
```




### References
* https://eksctl.io/
* https://eksctl.io/usage/dry-run/
* https://eksctl.io/usage/vpc-networking/
* https://eksctl.io/usage/vpc-configuration/
* https://eksctl.io/usage/creating-and-managing-clusters/
* https://eksctl.io/usage/schema/
* https://github.com/weaveworks/eksctl/tree/main/examples
* https://www.youtube.com/watch?v=gwmdboC-BtE