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

  # New in Lab 4: every instance in this subnet gets a public IP address.
  map_public_ip_on_launch = true

  tags = {
    Name = "training-subnet-1a"
  }
}

# The internet gateway connects the VPC to the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "training-igw"
  }
}

# A route table that sends all traffic (0.0.0.0/0) to the internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "training-public-rt"
  }
}

# Our subnet uses that route table.
resource "aws_route_table_association" "subnet_1a" {
  subnet_id      = aws_subnet.subnet_1a.id
  route_table_id = aws_route_table.public.id
}
