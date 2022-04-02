# VPC

Modify the parameters in deploy-vpc.sh and create a VPC stack.

The stack creates an S3 bucket, copies over all the files related to the VPC for the cloudformation template
and then launches the stack.

Refer to the following files for detailed information

* deploy-vpc.sh - Calls setup-vpc.sh with specific parameters to create stack
* params-dev.json - Override parameters for the VPC.
* setup-vpc.sh - creates and s3 bucket stack, copies files to the s3 bucket and run the cloudformation based on parameters passed.

## Templates
* bucket-vpc-template.yaml - All the cloudformation templates are banked here prior to execution.
* vpc-template.yaml - Cloudformation to create a VPC.

## Configs
* Houses the parameters per environment. The environment name provided in the deploy-*.sh is used to pick up the corresponding file required in the configs folder. For example if ther environment name is dev, the params-dev.json is picked up as a parameter.


## Implementation

### Deployment

```bash

./deploy-vpc.sh
```

Executing the above command

1. Creates a
   * Creates a CF stack by name ${STACK}-s3-cf-stack   
   * S3 Bucket by name ${STACK}-s3-cf-stack-s3-bucket
2. Pushes all files from the templates, scripts directory to the bucket
3. Runs the cloudformation templates from  S3
4. The bucket created to bank all cloudformation scripts is read to create the rest of the resources. 
   

Note:  Refer root-vpc.yaml which consolidates all the templates

### Cleaning up

```bash
./delete-cf-stack -s=<stack-name> -p=<profile>
```

Executing the above command does the following

* Deletes the root Cloudformation stack
* Empties the S3 bucket containing the cloudformation templates
* Deletes the Cloudformation stack used to create the S3 bucket which banks the CF templates