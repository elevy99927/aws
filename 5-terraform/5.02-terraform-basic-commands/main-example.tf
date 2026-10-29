# 1. Define the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# 2. Create the VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-custom-vpc"
  }
}

# 3. Create a Subnet inside the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id  # Links the subnet to the VPC
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true                  # Gives the EC2 instance a public IP

  tags = {
    Name = "my-public-subnet"
  }
}

# 4. Launch the EC2 Instance inside the Subnet
resource "aws_instance" "my_instance" {
  ami           = "ami-0c7217cdde317cfec"           # Replace with a valid AMI for your region
  instance_type = "t2.micro"

  # THIS LINE PLACES THE EC2 INSTANCE INSIDE YOUR VPC
  subnet_id     = aws_subnet.public_subnet.id       

  tags = {
    Name = "my-ec2-in-vpc"
  }
}