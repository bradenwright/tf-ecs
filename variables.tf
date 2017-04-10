
variable "aws_availability_zones" {
  type = "list"
  default = ["us-east-1a","us-east-1b"]
}

variable "docker_cpu" {
  default = 50
}

variable "docker_desired_count" {
  default = "16"
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
# Can specify DockerHub via: repository-url/image:tag
# Can specify ECR via: aws_account_id.dkr.ecr.region.amazonaws.com/my-web-app:latest
variable "docker_image" { 
  default = "training/webapp"
}

variable "docker_memory" {
  default = 100
}

variable "docker_placement_strategy" {
  description = "Placement strategy can be memory or cpu"
  default = "memory"
}

variable "ecs_instances_max_num" {
  default = "2"
}

variable "ecs_instances_min_num" {
  default = "2"
}

variable "ecs_instance_type" {
  default = "t2.micro"
}
