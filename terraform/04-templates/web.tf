resource "aws_instance" "web" {
 # ….

 user_data = “${data.template_file.web-config.rendered}”
}

