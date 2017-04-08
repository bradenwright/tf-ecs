
variable "app_name" { }

variable "aws_availability_zones" {
  type = "list"
}

variable "aws_subnet_ids" { 
  type = "list"
}

variable "aws_vpc_id" { }

variable "docker_cpu" { }
variable "docker_desired_count" { }

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
# Can specify DockerHub via: repository-url/image:tag
# Can specify ECR via: aws_account_id.dkr.ecr.region.amazonaws.com/my-web-app:latest
variable "docker_image" { }

variable "docker_memory" { }
variable "docker_placement_strategy" {
  description = "Placement strategy can be memory or cpu"
}

variable "docker_port" { }


variable "elb_port" {
  default = "80"
}

variable "ecs_ami_id" {
  description = "ami to use for ecs instances, by default finds the most recent ami optimized for ecs"
  default = false
}
                                                                                                      
variable "ecs_instances_max_num" { }
variable "ecs_instances_min_num" { }
variable "ecs_instance_type" { }

