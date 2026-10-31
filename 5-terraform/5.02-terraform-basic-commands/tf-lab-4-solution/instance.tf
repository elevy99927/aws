# Two instances in our subnet, with the key pair and the SSH security group.
# local-exec runs on your computer once each instance is created, and adds its name and IP to LAB-IPS.txt.
resource "aws_instance" "web_1" {
  ami                    = var.AMIS[var.AWS_REGION]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_1a.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "my-tf-web-1"
  }

  # The instances don't refer to the internet gateway, so we set the order ourselves:
  # the gateway is created first, and on destroy, removed after the instances.
  depends_on = [aws_internet_gateway.main]

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}

resource "aws_instance" "web_2" {
  ami                    = var.AMIS[var.AWS_REGION]
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_1a.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "my-tf-web-2"
  }

  # The instances don't refer to the internet gateway, so we set the order ourselves:
  # the gateway is created first, and on destroy, removed after the instances.
  depends_on = [aws_internet_gateway.main]

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}
