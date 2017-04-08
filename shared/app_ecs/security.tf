###################################################################################################
############################## IAM for ECS Cluster ################################################
###################################################################################################

resource "aws_iam_instance_profile" "ecs" {
  name  = "${terraform.env}-${var.app_name}-ecs-cluster"
  roles = ["${aws_iam_role.ecs.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs" {
  name = "${terraform.env}-${var.app_name}-ecs-cluster"
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
  name = "${terraform.env}-${var.app_name}-ecs-cluster"
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

###################################################################################################
############################## IAM for ECS Service ################################################
###################################################################################################

resource "aws_iam_role" "service" {
  name = "${terraform.env}-${var.app_name}-ecs-service"
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
  name = "${terraform.env}-${var.app_name}-ecs-service"
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


###################################################################################################
##################### Security Groups for ALB #####################################################
###################################################################################################

resource "aws_security_group" "alb" {
  vpc_id = "${var.aws_vpc_id}"
  name   = "${terraform.env}-${var.app_name}-alb"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0

    cidr_blocks = ["0.0.0.0/0"]
  }
}

###################################################################################################
##################### Security Groups for ECS Cluster #############################################
###################################################################################################

# http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PortMapping.html
# port mapping works for current ecs
resource "aws_security_group" "ecs_cluster" {
  description = "controls direct access to application instances"
  vpc_id      = "${var.aws_vpc_id}"
  name        = "${terraform.env}-${var.app_name}-ecs-cluster"

  ingress {
    protocol  = "tcp"
    from_port = 32768
    to_port   = 60999

    security_groups = [
      "${aws_security_group.alb.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
