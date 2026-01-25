resource "aws_instance" "web" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
  user_data = data.template_file.web-config.rendered
}


resource "aws_instance" "database1" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}


# print user_data as output
output "web_user_data" {
  value = aws_instance.web.user_data
}