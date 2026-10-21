# jb-lab-1 – ECS on EC2: cluster (Auto Scaling Group of ECS-optimized instances), task definition, service
#   terraform apply -var my_ip_cidr="$(curl -s https://checkip.amazonaws.com)/32"

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32 (allowed to reach port 8080)"
  type        = string
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# The latest ECS-optimized Amazon Linux 2023 AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# ---------- Part A: security group ----------
resource "aws_security_group" "instances" {
  name        = "jb-ecs-instances-sg"
  description = "ECS container instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- Part B: instance role, cluster, launch template, ASG ----------
resource "aws_iam_role" "instance" {
  name = "jb-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance" {
  name = "jb-ecs-instance-role"
  role = aws_iam_role.instance.name
}

resource "aws_ecs_cluster" "this" {
  name = "jb-ecs-ec2"
}

resource "aws_launch_template" "ecs" {
  name          = "jb-ecs-lt"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instances.id]
  }

  # The ECS agent reads the cluster name from /etc/ecs/ecs.config and registers the instance
  user_data = base64encode("#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config\n")

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "jb-ecs-instance" }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "jb-ecs-asg"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }
}

# ---------- Part C: task definition (static port 8080 -> 80) ----------
resource "aws_ecs_task_definition" "whoami" {
  family                   = "jb-whoami"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name         = "whoami"
    image        = "traefik/whoami"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 8080, protocol = "tcp" }]
  }])
}

# ---------- Part D: service ----------
resource "aws_ecs_service" "whoami" {
  name            = "whoami-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.whoami.arn
  desired_count   = 2
  launch_type     = "EC2"

  depends_on = [aws_autoscaling_group.ecs, aws_iam_role_policy_attachment.instance] # destroy the service before the agent loses its permissions
}

output "find_instance_ips" {
  value = "aws ec2 describe-instances --filters Name=tag:Name,Values=jb-ecs-instance Name=instance-state-name,Values=running --query 'Reservations[].Instances[].PublicIpAddress' --output text"
}
