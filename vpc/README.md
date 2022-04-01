# VPC

Modify the parameters in deploy-vpc.sh and create a VPC stack.

The stack creates an S3 bucket, copies over all the files related to the VPC for the cloudformation template
and then launches the stack.

Refer to the following files for detailed information

* deploy-vpc.sh - Calls setup-vpc.sh with specific parameters to create stack
* params-dev.json - Override parameters for the VPC.
* setup-vpc.sh - creates and s3 bucket stack, copies files to the s3 bucket and run the cloudformation based on parameters passed.

Templates
* bucket-vpc-template.yaml - All the cloudformation templates are banked here prior to execution.
* vpc-template.yaml - Cloudformation to create a VPC.