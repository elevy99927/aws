# Outputs print values after apply, and terraform output prints them again at any time.
# On Floci the public IP is 127.0.0.1; the instance id names its container (floci-aws-ec2-<id>) in docker ps.
output "web_1_public_ip" {
  value = aws_instance.web_1.public_ip
}

output "web_2_public_ip" {
  value = aws_instance.web_2.public_ip
}

output "web_1_id" {
  value = aws_instance.web_1.id
}

output "web_2_id" {
  value = aws_instance.web_2.id
}
