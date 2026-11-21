output "host_ip" {
  value = aws_instance.host.public_ip
}

output "ssh" {
  value = "ssh -i ssh/terraform-key ubuntu@${aws_instance.host.public_ip}"
}

output "progress" {
  value = "on the host: tail -f ~/fc/logs/*.log   (about 10 minutes; done when ~/fc/lab.done exists; ~/fc/lab.failed on an error)"
}
