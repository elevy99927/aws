variable "AWS_REGION" {
  default = "us-east-1"
}

# Your public IP address as a /32 range. Only this address can connect with SSH.
#   export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
variable "MY_IP" {
  type = string
}

# Nested virtualization (KVM inside the instance) needs one of the Intel families that support it.
# m7i-flex.large is the Free Tier eligible one, the same as in the Firecracker lab.
variable "INSTANCE_TYPE" {
  default = "m7i-flex.large"
}

# The repositories the webhook accepts (owner/name, comma-separated). A delivery from any other repository is rejected.
variable "REPOS" {
  default = "elevy99927/fc-agents-sample"
}
