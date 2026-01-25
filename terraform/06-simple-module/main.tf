provider "aws" {
  region = "eu-west-1"
}

module "web_server_1" {
  source = "./modules/web-server"
  
  ami_id        = "ami-096f46d460613bed4"  # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "my-key-pair"  # Replace with your key pair name
  server_name   = "web-server-1"
}

module "web_server_2" {
  source = "./modules/web-server"
  
  ami_id        = "ami-096f46d460613bed4"  # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "my-key-pair"  # Replace with your key pair name
  server_name   = "web-server-2"
}

resource "aws_instance" "database1" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}

# print user_data as output
output "web_user_data" {
  value = aws_instance.database1.user_data
}