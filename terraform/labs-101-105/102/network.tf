resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.example_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
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

#vpc/subnet
resource "aws_subnet" "example_subnet" {
  vpc_id                  = aws_vpc.example_vpc.id #reference to the VPC
  cidr_block              = "10.30.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "my-subnet",
    Create = "terraform"

  }
}

resource "aws_vpc" "example_vpc" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-vpc"
    Create = "terraform"
  }
}

