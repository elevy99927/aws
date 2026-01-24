resource "aws_instance" "web" {
  user_data = data.template_file.web-config.rendered
}


resource "aws_instance" "database1" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"
}
