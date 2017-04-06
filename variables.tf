variable "name" {
  default = "hello-world"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "ecs_ami" {
  description = "ami to use for ecs instances, by default finds the most recent ami optimized for ecs"
  default = false
 }

variable "ecs_docker_cpu" {
  default = "50"
}

variable "ecs_docker_memory" {
  default = "512"
}

variable "ecs_docker_port" {
  default = "5000"
}

variable "ecs_instance_port" {
  default = "5001"
}

variable "elb_port" {
  default = "80"
}

variable "max_num_ecs_instances" {
  default = "3"
}

variable "min_num_ecs_instances" {
  default = "3"
}

variable "aws_subnets" {
  type = "list"
  default = ["subnet-7d711657","subnet-c1d680b7"]
}
