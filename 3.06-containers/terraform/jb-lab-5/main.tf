# jb-lab-5 – ECS service auto scaling: a Fargate service behind the ALB that scales 1-4 tasks
# on ALB requests per target (target tracking). Standalone, with the whoami image (no ECR needed).

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

resource "aws_security_group" "tasks" {
  name        = "jb-fargate-tasks-sg"
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
  name               = "jb-ecs-alb"
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
  name = "jb-ecs-fargate"
}

resource "aws_iam_role" "execution" {
  name = "jb-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- Target group (type ip), listener rule /fargate* ----------
resource "aws_lb_target_group" "app" {
  name        = "jb-fargate-tg"
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
  priority     = 30

  condition {
    path_pattern {
      values = ["/fargate*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ---------- Fargate task definition ----------
resource "aws_ecs_task_definition" "app" {
  family                   = "jb-whoami-fargate"
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
    name         = "whoami"
    image        = "traefik/whoami"
    essential    = true
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
    environment  = [{ name = "WHOAMI_NAME", value = "fargate" }]
  }])
}

# ---------- Service ----------
resource "aws_ecs_service" "app" {
  name            = "whoami-fargate-svc"
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
    container_name   = "whoami"
    container_port   = 80
  }

  depends_on = [aws_lb_listener_rule.app, aws_iam_role_policy_attachment.execution]

  # the scaling policy changes the desired count; don't reset it on every apply
  lifecycle {
    ignore_changes = [desired_count]
  }
}

output "url" {
  value = "http://${aws_lb.this.dns_name}/fargate"
}

# ---------- Service auto scaling (Application Auto Scaling) ----------
resource "aws_appautoscaling_target" "app" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.app.name}"
  min_capacity       = 1
  max_capacity       = 4
}

resource "aws_appautoscaling_policy" "requests" {
  name               = "jb-web-requests"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.app.service_namespace
  scalable_dimension = aws_appautoscaling_target.app.scalable_dimension
  resource_id        = aws_appautoscaling_target.app.resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = 100
    scale_out_cooldown = 60
    scale_in_cooldown  = 120

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }
  }
}
