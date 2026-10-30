# Our own VPC: from now on, Terraform creates the network.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "training-vpc"
  }
}

# One subnet in us-east-1a. vpc_id refers to the VPC above, so Terraform creates the VPC first.
resource "aws_subnet" "subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "training-subnet-1a"
  }
}
