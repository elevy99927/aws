# Two instances in our subnet. subnet_id refers to the subnet, so Terraform creates the subnet first.
resource "aws_instance" "web_1" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1a.id

  tags = {
    Name = "my-tf-web-1"
  }
}

resource "aws_instance" "web_2" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_1a.id

  tags = {
    Name = "my-tf-web-2"
  }
}
