terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Credentials come from the AWS CLI (aws login, or a profile), never from this code.
provider "aws" {
  region = var.region
}

# The latest Amazon Linux 2023 AMI, so no AMI ID is hardcoded.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# No subnet_id: AWS uses the default subnet of this Availability Zone, in the default VPC.
resource "aws_instance" "lab" {
  ami               = data.aws_ami.al2023.id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone

  tags = {
    Name = "tf-lab-2"
  }
}
