provider "aws" {
  region = "${replace(element(var.aws_availability_zones,0),"/[a-z]$/","")}"
}

module "aws" {
  source = "./shared/aws"

  availability_zones = ["${var.aws_availability_zones}"]
}

module "app_ecs" {
  source = "./shared/app_ecs"

  app_name = "hello-world"

  aws_availability_zones = ["${var.aws_availability_zones}"]
  aws_subnet_ids = ["${module.aws.subnet_ids}"]
  aws_vpc_id = "${module.aws.vpc_id}"

  docker_cpu = "${var.docker_cpu}"
  docker_desired_count = "${var.docker_desired_count}"
  docker_image = "${var.docker_image}"
  docker_memory = "${var.docker_memory}"
  docker_placement_strategy = "${var.docker_placement_strategy}"
  docker_port = 5000

  ecs_instances_max_num = "${var.ecs_instances_max_num}"
  ecs_instances_min_num = "${var.ecs_instances_min_num}"
  ecs_instance_type = "${var.ecs_instance_type}"
}

