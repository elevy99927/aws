# A security group for our instances: SSH (port 22) only from your IP address.
resource "aws_security_group" "ssh" {
  name        = "training-ssh"
  description = "SSH from my IP"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "training-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = var.MY_IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Outbound traffic to anywhere, for example to install updates.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
