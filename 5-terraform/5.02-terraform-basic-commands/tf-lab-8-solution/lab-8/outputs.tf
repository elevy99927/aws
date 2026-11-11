# Use our Module output we wrote in the previous slide to output the # instances IP’s in our code.


# In your ROOT outputs.tf file:
output "servers-ip" { 
  value = module.module-example.instance_public_ip
}