# Two instances in our subnet, with the key pair and the SSH security group.
# user-data installs nginx at first boot; remote-exec waits for it and checks the page over SSH;
# local-exec runs on your computer once each instance is created, and adds its name and IP to LAB-IPS.txt.
resource "aws_instance" "web_1" {
  ami                    = var.AMIS[var.AWS_REGION]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_1a.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.lab.key_name

  # New in Lab 7: the user-data script comes from a template, with values filled in by Terraform.
  user_data = templatefile("install-nginx.sh.tftpl", {
    server_name = "web-1"
    bucket      = aws_s3_bucket.lab.bucket
  })
  user_data_replace_on_change = true

  tags = {
    Name = "my-tf-web-1"
  }

  # The instances don't refer to the internet gateway, so we set the order ourselves:
  # the gateway is created first, and on destroy, removed after the instances.
  depends_on = [aws_internet_gateway.main]

  # New in Lab 5: Terraform connects over SSH, waits for user-data to finish, and checks nginx.
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-ssh-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "systemctl is-active nginx",
      "curl -s localhost",
    ]
  }

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

  # New in Lab 7: the user-data script comes from a template, with values filled in by Terraform.
  user_data = templatefile("install-nginx.sh.tftpl", {
    server_name = "web-2"
    bucket      = aws_s3_bucket.lab.bucket
  })
  user_data_replace_on_change = true

  tags = {
    Name = "my-tf-web-2"
  }

  # The instances don't refer to the internet gateway, so we set the order ourselves:
  # the gateway is created first, and on destroy, removed after the instances.
  depends_on = [aws_internet_gateway.main]

  # New in Lab 5: Terraform connects over SSH, waits for user-data to finish, and checks nginx.
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-ssh-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "systemctl is-active nginx",
      "curl -s localhost",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}
