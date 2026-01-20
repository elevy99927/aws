resource "aws_instance" "app_server" {
  ami           = data.aws_ami.linux.id
  instance_type = "t2.micro"

  tags = {
    Name = "hashicorp-learn"
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.app_server.private_ip} >> private_ips.txt"
  }
}

output "ip" {
  value = aws_instance.app_server.public_ip
}

