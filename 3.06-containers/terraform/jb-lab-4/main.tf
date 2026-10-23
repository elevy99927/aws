# Lab 4 – Amazon ECR: a private repository, and the image deployed on Fargate behind the ALB (/web)
#
# Two steps, because the image must exist in ECR before ECS can run it:
#   1. terraform apply -target=aws_ecr_repository.web     # create the repository
#   2. build + push the image (see jb-lab-4-solution.md, Part C)
#   3. terraform apply -var image_tag=v1                  # everything else
# Roll out v2: push v2, then  terraform apply -var image_tag=v2

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "image_tag" {
  description = "The tag to deploy. Push it to the repository first (see the solution)."
  type        = string
  default     = "v1"
}

# ---------- ECR repository + lifecycle policy ----------
resource "aws_ecr_repository" "web" {
  name         = "web"
  force_delete = true # lets "terraform destroy" delete it even with images inside

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "web" {
  repository = aws_ecr_repository.web.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the 2 most recent images"
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 2 }
      action       = { type = "expire" }
    }]
  })
}

output "repository_url" {
  value = aws_ecr_repository.web.repository_url
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
    name   = "default-for-az"
    values = ["true"]
  }
}

data "aws_subnets" "tasks" {
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

# ---------- Security groups: ALB (internet) -> tasks (only from the ALB) ----------
resource "aws_security_group" "alb" {
  name        = "ecs-alb-sg"
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

resource "aws_security_group" "tasks" {
  name        = "fargate-tasks-sg"
  description = "Fargate tasks - HTTP only from the ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
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

# ---------- ALB with a default 404 ----------
resource "aws_lb" "this" {
  name               = "ecs-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
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

# ---------- Fargate-only cluster and the task execution role ----------
resource "aws_ecs_cluster" "this" {
  name = "ecs-fargate"
}

resource "aws_iam_role" "execution" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- Target group (type ip), listener rule /web* ----------
resource "aws_lb_target_group" "app" {
  name        = "web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip" # Fargate tasks register by IP (awsvpc)

  health_check {
    path                = "/"
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  condition {
    path_pattern {
      values = ["/web*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------- Fargate task definition ----------
resource "aws_ecs_task_definition" "app" {
  family                   = "web"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name         = "web"
    image        = "${aws_ecr_repository.web.repository_url}:${var.image_tag}"
    essential    = true
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
  }])
}

# ---------- Service ----------
resource "aws_ecs_service" "app" {
  name            = "web-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.tasks.ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true # needed to pull images from the internet in a public subnet
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.app, aws_iam_role_policy_attachment.execution]
}

output "url" {
  value = "http://${aws_lb.this.dns_name}/web/"
}
