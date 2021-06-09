# dataworks-aws-data-egress

## A repo for Dataworks AWS Data Egress service infrastructure

This repo contains Makefile and base terraform folders and jinja2 files to fit the standard pattern.
This repo is a base to create new Terraform repos, renaming the template files and adding the githooks submodule, making the repo ready for use.

Running aviator will create the pipeline required on the AWS-Concourse instance, in order pass a mandatory CI ran status check.  this will likely require you to login to Concourse, if you haven't already.

After cloning this repo, please generate `terraform.tf` and `terraform.tfvars` files:  
`make bootstrap`

In addition, you may want to do the following: 

1. Create non-default Terraform workspaces as and if required:  
    `make terraform-workspace-new workspace=<workspace_name>` e.g.  
    ```make terraform-workspace-new workspace=qa```

1. Configure Concourse CI pipeline:
    1. Add/remove jobs in `./ci/jobs` as required 
    1. Create CI pipeline:  
`aviator`

## SFT Agent

The SFT Agent reads files written to disk by the data egress service and sends these to configured destinations via HTTPS. 
It is deployed as a sidecar to the data egress service, and a volume mounted to /data-egress is 
shared between the containers.  
Which files are read and where they are sent to is determined by [config](sft_config/agent-application-config.tpl)

## Testing
In non production environments files are send to stub nifi, which is a container running nifi deployed by snapshot sender. This listens for
files sent on port 8091 on path /DA. 
The files it receives will be saved to the s3 bucket 
```
stub-hdfs-****

```
