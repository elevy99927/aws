# SSH (port 22) only from your IP address. Nothing else comes in.
resource "aws_security_group" "host" {
  name        = "fc-agents-host"
  description = "SSH from my IP"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "fc-agents-host" }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.host.id
  cidr_ipv4         = var.MY_IP
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# Out to anywhere: the host downloads Firecracker, the kernel and Ubuntu, and the guest pulls Docker images.
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
