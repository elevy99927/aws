# An SSH key pair for the host, made by Terraform. The private key is saved in ssh/terraform-key (gitignored).
resource "tls_private_key" "host" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "host" {
  key_name   = "fc-agents-host-key"
  public_key = tls_private_key.host.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.host.private_key_openssh
  filename        = "${path.module}/ssh/terraform-key"
  file_permission = "0600"
}
