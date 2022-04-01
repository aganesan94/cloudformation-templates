#!/bin/bash

FILE_NAME=deploy-dev.sh

# Specify an AWS Profile to use
AWS_PROFILE=cloudtel

# Stack name to be built
STACK_NAME=dev-vpc

ENVIRONMENT_NAME=dev

#S3 bucket to house the cloudformation templates.
S3_BUCKET_STACK=$STACK_NAME-sources

if [[ -z $AWS_PROFILE ]]; then
  echo "`date`-$FILE_NAME: Please enter a valid AWS_PROFILE to use."
fi

if [[ -z $STACK_NAME ]]; then
  echo "`date`-$FILE_NAME: Please enter a valid STACK_NAME to use."
fi

echo "`date`-$FILE_NAME: ./setup-vpc.sh -p $AWS_PROFILE -s $STACK_NAME -e $ENVIRONMENT_NAME"
./setup-vpc.sh -p $AWS_PROFILE -s $STACK_NAME -e $ENVIRONMENT_NAME