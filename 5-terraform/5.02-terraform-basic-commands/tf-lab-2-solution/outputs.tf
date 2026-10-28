output "instance_id" {
  value = aws_instance.lab.id
}

output "availability_zone" {
  value = aws_instance.lab.availability_zone
}

output "ami" {
  value = data.aws_ami.al2023.name
}
