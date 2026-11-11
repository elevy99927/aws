# Outputs print values after apply, and terraform output prints them again at any time.
output "web_1_public_ip" {
  value = aws_instance.web_1.public_ip
}

output "web_2_public_ip" {
  value = aws_instance.web_2.public_ip
}

# New in Lab 5: the address of each web page.
output "web_1_url" {
  value = "http://${aws_instance.web_1.public_ip}"
}

output "web_2_url" {
  value = "http://${aws_instance.web_2.public_ip}"
}
