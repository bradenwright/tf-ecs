
###################################################################################################
######################## Create ALB ###############################################################
###################################################################################################

resource "aws_alb" "ecs" {
  name            = "${terraform.env}-${var.app_name}"
  subnets         = ["${var.aws_subnet_ids}"]
  security_groups = ["${aws_security_group.alb.id}"]
}

resource "aws_alb_listener" "ecs" {
  load_balancer_arn = "${aws_alb.ecs.id}"
  port              = "${var.elb_port}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecs.id}"
    type             = "forward"
  }

  depends_on = ["aws_alb.ecs"]
}

resource "aws_alb_target_group" "ecs" {
  name     = "${terraform.env}-${var.app_name}"
  port     = "${var.elb_port}"
  protocol = "HTTP"
  vpc_id   = "${var.aws_vpc_id}"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 15
  }
}

###################################################################################################
############################### ECS Cluster #######################################################
###################################################################################################

# Find most recent ecs optimized ami
data "aws_ami" "ecs" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${terraform.env}-${var.app_name}"
}

# If var.ecs_ami_id is set use it, otherwise use data.aws_ami.ecs.id
resource "aws_launch_configuration" "ecs" {
  name_prefix = "${terraform.env}-${var.app_name}-"
  instance_type = "${var.ecs_instance_type}"
  image_id = "${var.ecs_ami_id ? var.ecs_ami_id : data.aws_ami.ecs.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  security_groups = ["${aws_security_group.ecs_cluster.id}"]

  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${terraform.env}-${var.app_name}" >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name = "${terraform.env}-${var.app_name}"
  availability_zones = ["${var.aws_availability_zones}"]
  max_size = "${var.ecs_instances_max_num}"
  min_size = "${var.ecs_instances_min_num}"
  launch_configuration = "${aws_launch_configuration.ecs.name}"

  tag {
    key = "Name"
    value = "ecs-${terraform.env}-${var.app_name}"
    propagate_at_launch = true
  }
}

###################################################################################################
############################### ECS Service #######################################################
###################################################################################################

resource "aws_ecs_service" "service" {
  name            = "${terraform.env}-${var.app_name}"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.service.arn}"
  desired_count   = "${var.docker_desired_count}"
  iam_role        = "${aws_iam_role.service.arn}"

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "binpack"
    field = "${var.docker_placement_strategy}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ecs.id}"
    container_name = "${terraform.env}-${var.app_name}"
    container_port = "${var.docker_port}"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(",",var.aws_availability_zones)}]"
  }

  depends_on = [
    "aws_iam_role_policy.service",
    "aws_alb_listener.ecs"
  ]
}

resource "aws_ecs_task_definition" "service" {
  family = "${terraform.env}-${var.app_name}"
  container_definitions = <<EOF
[
  {
    "name": "${terraform.env}-${var.app_name}",
    "image": "${var.docker_image}",
    "cpu": ${var.docker_cpu},
    "memory": ${var.docker_memory},
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.docker_port}
      }
    ]
  }
]
EOF

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(",",var.aws_availability_zones)}]"
  }
}

