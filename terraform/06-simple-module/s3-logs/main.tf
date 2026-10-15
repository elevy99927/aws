provider "aws" {
  region = "eu-west-1"
}



resource "aws_lb" "app" {
  name               = "app-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets

  access_logs {
    bucket  = module.s3_bucket_for_logs.s3_bucket_id
    prefix  = "alb"
    enabled = true
  }
}
