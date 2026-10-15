output "web_server_1_ip" {
  description = "Public IP of web server 1"
  value       = module.web_server_1.public_ip
}

output "web_server_2_ip" {
  description = "Public IP of web server 2"
  value       = module.web_server_2.public_ip
}

output "web_server_1_url" {
  description = "URL for web server 1"
  value       = "http://${module.web_server_1.public_ip}"
}

output "web_server_2_url" {
  description = "URL for web server 2"
  value       = "http://${module.web_server_2.public_ip}"
}