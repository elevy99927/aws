# use pre-existing key pair #create by generete_ssh.sh
resource "aws_key_pair" "example" {
  key_name   = "terraform-key"
  public_key = file("${path.module}/ssh/terraform-key.pub")
}



resource "aws_instance" "vm" {
  ami           = "ami-0b6c6ebed2801a5cb" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg.id]   #reference to the security group id in network.tf
  subnet_id     = aws_subnet.example_subnet.id             #reference to the subnet id in network.tf
  key_name      = aws_key_pair.example.key_name        #reference to the key above


  #how our remote-exec script will connect to the vm
  connection {
    type        = "ssh"
    user        = "ubuntu"   #if not working, check vars.tf -> AMIS
    private_key = try(file("${path.module}/ssh/terraform-key"), "")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install nginx -y "
    ]
  }


  tags = {
    Name = "elevy-vm",
    Create = "terraform"
  }

}

#print output
output "vm_public_ip" {
  value       = aws_instance.vm.public_ip
  description = "Public IP address of the VM"
}

