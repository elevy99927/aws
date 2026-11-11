resource "aws_instance" "example" {
  count = var.number-instances # This will build x of this 
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"
  #provisioner "local-exec" {
   # command = "echo ${aws_instance.example[*].public_dns} >> dns.txt"
  #}
  key_name = aws_key_pair.example.key_name

 connection {
   type        = "ssh"
   user        = "ubuntu" #if not working, check vars.tf -> AMIS
   private_key = try(file("./ssh/terraform-key"), "")
   host        = self.public_ip
 }
  
#Define User-data
 user_data = templatefile("../modules/jb-module/user-data.sh.tftpl", {
   server_name = "example"
   bucket      = "my-bucket"
 })

 user_data_replace_on_change = true


 provisioner "remote-exec" {
   inline = [
     "cloud-init status --wait", # user-data has finished
     "sudo docker ps",
     "curl -s localhost | head -5" # the nginx welcome page
   ]
 }

}

resource "aws_key_pair" "example" {
  key_name   = "deployer-key"
  public_key = file("./ssh/terraform-key.pub")
}



output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.example[*].public_ip
}
