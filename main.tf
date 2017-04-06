provider "aws" {
  region = "${var.aws_region}"
}

###################################################################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}"
}

data "aws_ami" "ecs" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_launch_configuration" "ecs" {
  name_prefix = "${var.name}-"
  instance_type = "${var.aws_instance_type}"
  image_id = "${data.aws_ami.ecs.id}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"

  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${var.name}" >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name = "${var.name}"
  availability_zones = ["us-east-1a","us-east-1b"]
  min_size = "${var.min_num_ecs_instances}"
  max_size = "${var.max_num_ecs_instances}"
  launch_configuration = "${aws_launch_configuration.ecs.name}"

  tag {
    key = "Name"
    value = "ecs-${var.name}"
    propagate_at_launch = true
  }
}

resource "aws_iam_instance_profile" "ecs" {
  name  = "ecs"
  roles = ["${aws_iam_role.ecs.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs" {
  name = "ecs_instances"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "ecs" {
  name = "ecs"
  role = "${aws_iam_role.ecs.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

###################################################################################

resource "aws_ecs_service" "service" {
  name            = "${var.name}"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.service.arn}"
  desired_count   = 21
  iam_role        = "${aws_iam_role.service.arn}"
  depends_on      = ["aws_iam_role_policy.service"]

  placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ecs.id}"
    container_name = "${var.name}"
    container_port = 5000
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }

  depends_on = ["aws_alb_listener.ecs"]
}


resource "aws_iam_role" "service" {
  name = "${var.name}"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "service" {
  name = "${var.name}"
  role = "${aws_iam_role.service.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

//        "hostPort": 5000
resource "aws_ecs_task_definition" "service" {
  family = "${var.name}"
  container_definitions = <<EOF
[
  {
    "name": "${var.name}",
    "image": "training/webapp",
    "cpu": 100,
    "memory": 100,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 5000
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
    expression = "attribute:ecs.availability-zone in [us-east-1a, us-east-1b]"
  }
}

/*
resource "aws_elb" "ecs" {
  name = "${var.name}"
  availability_zones = ["us-east-1a", "us-east-1b"]

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 30

    target = "HTTP:5000/"
  }

  listener {
    instance_port = "5000"
    instance_protocol = "http"
    lb_port = "80"
    lb_protocol = "http"
  }
}
*/

data "aws_vpc" "default" {
  default = true
}

resource "aws_alb_target_group" "ecs" {
  name     = "${var.name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.default.id}"

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 15
  }
}

resource "aws_alb" "ecs" {
  name            = "${var.name}"
  subnets         = ["${var.aws_subnets}"]
}

resource "aws_alb_listener" "ecs" {
  load_balancer_arn = "${aws_alb.ecs.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecs.id}"
    type             = "forward"
  }
}

