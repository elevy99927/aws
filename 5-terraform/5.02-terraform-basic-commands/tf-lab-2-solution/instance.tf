# No subnet: AWS launches the instance in the default VPC.
resource "aws_instance" "example" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"

  tags = {
    Name = "tf-example"
  }
}
