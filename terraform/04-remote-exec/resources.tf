# Generate SSH key pair before creating the key pair in AWS
# This ensures that the private key is available locally for SSH access
# `null_resource` is a resource used to control execution order or run provisioners, without creating infrastructure.
resource "null_resource" "generate_ssh_key" {
  provisioner "local-exec" {
    command = "sh ./generate_ssh_key.sh"
  }
}

locals {
  public_key_file = "${path.module}/ssh/terraform-key.pub"
}

resource "aws_key_pair" "example" {
  key_name   = "terraform-key"
  public_key = try(file(local.public_key_file), "")

  # Ensure the SSH key is generated before creating the key pair in AWS
  depends_on = [null_resource.generate_ssh_key]
}


resource "aws_instance" "example" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"   #if not working, check vars.tf -> AMIS
    private_key = file("${path.module}/ssh/terraform-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update"
    ]
  }
}