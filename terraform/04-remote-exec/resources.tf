# Generate SSH key pair before creating the key pair in AWS
# This ensures that the private key is available locally for SSH access
# run 'sh ./generate_ssh_key.sh'


# use pre-existing key pair
resource "aws_key_pair" "example" {
  key_name   = "terraform-key"
  public_key = file("${path.module}/ssh/terraform-key.pub")
}

# Create EC2 instance with pre-existing key pair
resource "aws_instance" "example" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"
  key_name      = aws_key_pair.example.key_name

  connection {
    type        = "ssh"
    user        = "ubuntu"   #if not working, check vars.tf -> AMIS
    private_key = try(file("${path.module}/ssh/terraform-key"), "")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update"
    ]
  }
}