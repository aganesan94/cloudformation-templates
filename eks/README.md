# EKS Tutorial

## Pre-requisites
* kubectl (https://kubernetes.io/docs/tasks/tools/)
  * Make sure to have auto-completion of bash installed (https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)
* awscli (https://docs.aws.amazon.com/cli/latest//getting-started-install.html)
  * If you already have it use the latest and greatest by upgrading your aws-cli
* jq (https://stedolan.github.io/jq/download/)
* yq (https://github.com/mikefarah/yq)
* IAM user with admin access is preferrable
* You will need to create a KMS Key to be used when encrypting kubernetes secrets
* EKSCTL installation (https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)


## References
https://kubernetes.io/docs/reference/kubectl/cheatsheet/