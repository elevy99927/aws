# jb-lab-2 – ECS service load balancing: two services (admin, store) with dynamic host ports
# behind one ALB with path-based routing. Standalone: it also builds the EC2 cluster from jb-lab-1.

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
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

  # Dynamic host ports: only the ALB may reach them
  ingress {
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
  instance_type = "t3.micro"

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

# ---------- ALB security group ----------
resource "aws_security_group" "alb" {
  name        = "jb-ecs-alb-sg"
  description = "ECS ALB - HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_subnets" "all_default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# ---------- ALB, listener (default 404) and path rules ----------
resource "aws_lb" "this" {
  name               = "jb-ecs-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.all_default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "no route"
      status_code  = "404"
    }
  }
}

locals {
  services = { admin = 10, store = 20 } # service name => listener rule priority
}

resource "aws_lb_target_group" "svc" {
  for_each    = local.services
  name        = "jb-${each.key}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "svc" {
  for_each     = local.services
  listener_arn = aws_lb_listener.http.arn
  priority     = each.value

  condition {
    path_pattern {
      values = ["/${each.key}*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }
}

# ---------- Task definitions with dynamic host ports (hostPort = 0) ----------
resource "aws_ecs_task_definition" "svc" {
  for_each                 = local.services
  family                   = "jb-${each.key}"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "128"
  memory                   = "128"

  container_definitions = jsonencode([{
    name         = "whoami"
    image        = "traefik/whoami"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 0, protocol = "tcp" }]
    environment  = [{ name = "WHOAMI_NAME", value = each.key }]
  }])
}

# ---------- Services registered with the target groups ----------
resource "aws_ecs_service" "svc" {
  for_each        = local.services
  name            = "${each.key}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.svc[each.key].arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.svc[each.key].arn
    container_name   = "whoami"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.svc, aws_autoscaling_group.ecs, aws_iam_role_policy_attachment.instance] # destroy the services before the agent loses its permissions
}

output "urls" {
  value = ["http://${aws_lb.this.dns_name}/admin", "http://${aws_lb.this.dns_name}/store"]
}
