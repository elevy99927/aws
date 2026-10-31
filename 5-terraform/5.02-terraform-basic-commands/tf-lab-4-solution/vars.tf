# Credentials. Leave them empty (null) to use your `aws login` session,
# or set them in the shell, never in this file:
#   export TF_VAR_AWS_ACCESS_KEY=...   export TF_VAR_AWS_SECRET_KEY=...
variable "AWS_ACCESS_KEY" {
  type      = string
  default   = null
  sensitive = true
}

variable "AWS_SECRET_KEY" {
  type      = string
  default   = null
  sensitive = true
}

# Only for temporary keys (they come with a session token).
variable "AWS_SESSION_TOKEN" {
  type      = string
  default   = null
  sensitive = true
}

variable "AWS_REGION" {
  default = "us-east-1"
}

# The AMIS map matches the AMI to the Region we work in (Amazon Linux 2023, release 2023.12.20261028.0).
# AMI IDs change with every release: the lab page shows how to look up the current one.
variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-041607313c6a2a618"
    us-west-2 = "ami-0f94ecc636ab88a17"
    eu-west-1 = "ami-06d02322fd0dc8fb2"
  }
}

# Your public IP address as a /32 range, for example 203.0.113.10/32. Only this address can connect with SSH.
#   export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
variable "MY_IP" {
  type = string
}
