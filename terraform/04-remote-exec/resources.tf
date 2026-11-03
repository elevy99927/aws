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
  ami                    = var.AMIS[var.AWS_REGION]
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  # user-data.sh installs Docker and runs nginx on port 80 at the first boot.
  user_data                   = file("user-data.sh")
  user_data_replace_on_change = true # user data runs only at the first boot, so a changed script gets a new instance (default: false, the old instance keeps the old script)

  connection {
    type        = "ssh"
    user        = "ubuntu" #if not working, check vars.tf -> AMIS
    private_key = try(file("${path.module}/ssh/terraform-key"), "")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait", # user-data has finished
      "sudo docker ps",
      "curl -s localhost | head -5" # the nginx welcome page
    ]
  }
}

output "url" {
  value = "http://${aws_instance.example.public_ip}"
}