# 3.10 Advanced EC2 – the final result of LAB 1 + LAB 2 + LAB 3 as code:
# ALB + target group + Launch Template + Auto Scaling Group (requests-per-target scaling)
# + Route 53 private hosted zone with an alias record to the ALB.
#
# Terraform is taught later in the course. This file is here as a reference.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

# ---------- Default VPC and its subnets ----------

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
    values = var.azs
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---------- LAB 1: security groups (SG chain) ----------

resource "aws_security_group" "alb" {
  name        = "lab-alb-sg"
  description = "Lab ALB - HTTP from anywhere"
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

resource "aws_security_group" "web" {
  name        = "lab-web-sg"
  description = "Lab web servers - HTTP only from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # only from the ALB's SG
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- LAB 1: target group + ALB + listener ----------

resource "aws_lb_target_group" "web" {
  name     = "lab-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "web" {
  name               = "lab-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ---------- LAB 2: IAM role for Session Manager ----------

resource "aws_iam_role" "ssm" {
  name = "lab-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "lab-ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}

# ---------- LAB 2: Launch Template + Auto Scaling Group ----------

resource "aws_launch_template" "web" {
  name                   = "lab-web-lt"
  image_id               = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = filebase64("${path.module}/../artifacts/user-data.sh")

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm.name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "lab-asg-web" }
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "lab-web-asg"
  min_size                  = 1
  desired_capacity          = 2
  max_size                  = 4
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 90
  default_instance_warmup   = 60

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # the scaling policy changes desired capacity; don't fight it on the next apply
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "requests_per_target" {
  name                   = "lab-requests-per-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    target_value = 100
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.web.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }
  }

  depends_on = [aws_lb_listener.http] # the metric exists only once the TG is behind a listener
}

# ---------- LAB 3: Route 53 private hosted zone ----------

resource "aws_route53_zone" "private" {
  name    = "app.internal"
  comment = "Lab 3.10 private zone"

  vpc {
    vpc_id = data.aws_vpc.default.id
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "www.app.internal"
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

# ---------- Outputs ----------

output "alb_url" {
  value = "http://${aws_lb.web.dns_name}"
}

output "private_url" {
  value = "http://www.app.internal (resolves only inside the VPC)"
}
