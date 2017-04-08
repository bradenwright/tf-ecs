# tf-spothero-app-ecs
Terraform to create an ECS cluster of Docker container, in this case a hello world python app

## Quick Overview

Creates an Application Load Balancer, ASG of ECS instances (by default finds latest ecs optimized image, this can be overriden), ECS cluster & service.  As well as some IAM and SG's.  ECS has CloudWatch metrics built in.

I went ahead and used an application elb instead of a classic elb, so multiple containers for a service can be run on a single ECS/EC2 instance.  By default I setup 2 instances in default AZ's for a redundant application.  I also went ahead and created a module which would allow for another application to be created quickly.  It also can have advantages of using multiple state files if one wanted.

## Setup

1. Install and configure aws cli, specifically need aws_access_key_id and aws_secret_access_key
2. Install Terraform, tested with 0.9.2
3. git clone https://github.com/bradenwright/tf-spothero
4. cd into tf-spothere and run `terraform get` to import modules

## Example Commands

### To create infrastructure and deploy docker container

`terraform apply` once completed a url will be outputted.  It may take a few minutes for Containers to be active in Load Balancer.

### To deploy a new docker container

Push a new container to url (such as docker hub) and re-run `terraform apply`, it pulls from the latest version so it will automagically deploy new container

### Deploy a new docker container with specific url/version

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html

Can specify DockerHub via: repository-url/image:tag

Can specify ECR via: aws_account_id.dkr.ecr.region.amazonaws.com/image:tag

`terraform apply -var 'docker_image=docker-training/webapp'`

`terraform apply -var 'docker_image=docker-training/webapp:latest'`

### Clean up
`terraform destroy -force`

### Environments

To spin up multiple versions of the same app use `terraform env` commands.  https://www.terraform.io/docs/state/environments.html

To create a new env named dev and switch to it `terraform env new dev`

To switch back to default env `terraform env select default`

## Next Steps
- Autoscale up/down policies
- Move ECS Cluster into its own module, so it could be reused for multiple applications
- tfvar files for different environments, e.g. dev, prod, bwright, etc.
- tag terraform_env, app_name

