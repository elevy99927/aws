resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.web.id]

#  user_data = <<-EOF
#    #!/bin/bash
#    yum update -y
#    yum install -y httpd
#    systemctl start httpd
#    systemctl enable httpd
#    echo "<h1>Hello from ${var.server_name}!</h1>" > /var/www/html/index.html
#  EOF

  tags = {
    Name = var.server_name
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.server_name}-"
  description = "Security group for web server"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
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