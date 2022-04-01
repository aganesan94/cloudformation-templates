#!/bin/bash
# Delete the cloudformation stack

FILE_NAME=delete-cf-stack

for i in "$@"; do
  case $i in
    -s=* | --stackName=*)
    STACK_NAME="${i#*=}"
    ;;
    -p=* | --awsProfile=*)
    AWS_PROFILE="${i#*=}"
    ;;    
  *)
    echo "Usage: sudo ./delete-cf-stack  -s=<stackName> -p=<awsProfile>"
    exit 1
    ;;
  esac
done

if [ -z "$STACK_NAME" ]
then
  echo "Usage: sudo ./delete-cf-stack  -s=<stackName> -p=<awsProfile>"
  exit 1
fi

if [ -z "$AWS_PROFILE" ]
then
  echo "Usage: sudo ./delete-cf-stack  -s=<stackName> -p=<awsProfile>"
  exit 1
fi


read -p "Are you sure you want to delete stack $STACK_NAME ? (y/n) " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "`date`-$FILE_NAME: AWS_PROFILE=$AWS_PROFILE aws cloudformation delete-stack --stack-name $STACK_NAME"
    AWS_PROFILE=$AWS_PROFILE aws cloudformation delete-stack --stack-name $STACK_NAME

    read -p "Are you sure you want to delete objects inside s3 bucket $STACK_NAME-s3-stack-s3-bucket ? (y/n) " -n 1 -r
    echo    # (optional) move to a new line

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "`date`-$FILE_NAME: AWS_PROFILE=$AWS_PROFILE aws s3 rm --recursive s3://$STACK_NAME-s3-stack-s3-bucket"
        AWS_PROFILE=$AWS_PROFILE aws s3 rm --recursive s3://$STACK_NAME-s3-stack-s3-bucket

        read -p "Are you sure you want to delete objects inside stack $STACK_NAME-s3-stack? (y/n) " -n 1 -r
        echo    # (optional) move to a new line

        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "`date`-$FILE_NAME: AWS_PROFILE=$AWS_PROFILE aws cloudformation delete-stack --stack-name $STACK_NAME-s3-stack"
            AWS_PROFILE=$AWS_PROFILE aws cloudformation delete-stack --stack-name $STACK_NAME-s3-stack   
        fi
    fi
fi    