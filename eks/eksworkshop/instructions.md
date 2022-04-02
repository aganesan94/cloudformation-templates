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




## Do this before you run the EKS commands




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
  instanceType: t3.micro
  ssh:
    enableSsm: true

# To enable all of the control plane logs, uncomment below:
# cloudWatch:
#  clusterLogging:
#    enableTypes: ["*"]

secretsEncryption:
  keyARN: ${MASTER_ARN}
```
