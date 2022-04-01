#!/bin/bash

# This is a simple bash script for creating a VPC

ERROR_COUNT=0; 

if [[ $# -lt 3 ]] ; then
    echo 'arguments missing, please provide atleast VPC and stack name.'
    exit 1
fi

while getopts ":p:s:e:" opt; do
  case $opt in
    p) AWS_PROFILE="$OPTARG"
    ;;
    e) ENVIRONMENT_NAME="$OPTARG"
    ;;    
    s) STACK="$OPTARG"
    ;;
    \?) echo "`date`: Invalid option -$OPTARG" >&2
    ;;
  esac
done

if ! [ -x "$(command -v aws)" ]; then
  echo '`date`: ERROR: aws cli is not installed.' >&2
  exit 1
fi

echo "`date`: using AWS Profile $AWS_PROFILE"
echo "`date`: Stack $STACK"
echo "`date`: Environment Name $ENVIRONMENT_NAME"

# Loop through the YAML templates in this repository
for TEMPLATE in $(find . -name '*-template.yaml'); do 

    # Validate the template with CloudFormation
    ERRORS=$(aws cloudformation validate-template --profile=$AWS_PROFILE --template-body file://$TEMPLATE 2>&1 >/dev/null); 
    if [ "$?" -gt "0" ]; then 
        ((ERROR_COUNT++));
        echo "`date`: [fail] $TEMPLATE: $ERRORS";
    else 
        echo "`date`: [pass] $TEMPLATE";
    fi; 
    
done; 

# Error out if templates are not validate. 
echo "$ERROR_COUNT template validation error(s)"; 
if [ "$ERROR_COUNT" -gt 0 ]; 
    then exit 1; 
fi

echo "`date`: Validating of AWS CloudFormation templates finished"


# Deploy the Needed Buckets for the later build 
echo "`date`: Deploying VPC"
PREPSTACK="${STACK}-s3-stack"
echo "`date`: S3 Stack Name $PREPSTACK"
aws cloudformation deploy --stack-name $PREPSTACK --profile=$AWS_PROFILE --template ./templates/bucket-vpc-template.yaml
echo "`date`: Deployment done"

# get the s3 bucket name out of the deployment.
SOURCE=`aws cloudformation describe-stacks --profile=$AWS_PROFILE --query "Stacks[0].Outputs[0].OutputValue" --stack-name $PREPSTACK`

SOURCE=`echo "${SOURCE//\"}"`

# we will upload the needed CFN Templates to S3 containing the IaaC Code which deploys the actual infrastructure.
# This will error out if the source files are missing. 
echo "`date`: ##################################################"
echo "`date`: Copy Files to the S3 Bucket for further usage"
echo "`date`: ##################################################"
if [ -e . ]
then
    echo "`date`: ##################################################"
    aws s3 sync --profile=$AWS_PROFILE --exclude=".DS_Store" ./templates s3://$SOURCE
    echo "`date`: ##################################################"
else
    echo "`date`: Code source file missing"
    echo "`date`: ##################################################"
    exit 1
fi
echo "`date`: ##################################################"
echo "`date`: File Copy finished"

# Setting the dynamic Parameters for the Deployment
PARAMETERS="VPCS3Stack=$PREPSTACK"

# Deploy the BBB infrastructure. 
echo "`date`: Building the BBB Environment"
echo "`date`: ##################################################"
aws cloudformation deploy --profile=$AWS_PROFILE --stack-name $STACK \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides $PARAMETERS \
    $(jq -r '.Parameters | to_entries | map("\(.key)=\(.value)") | join(" ")' ./configs/params-$ENVIRONMENT_NAME.json) \
    --template ./root-vpc.yaml

echo "`date`: ##################################################"
echo "`date`: Deployment finished"

exit 0