
variable "AWS_REGION" {
  default = "eu-west-1"
}

# Ubuntu 24.04 LTS (Canonical), amd64, 2026-11-03. The old eu-west-1 id was Amazon Linux 2023 (no "ubuntu" user, no apt),
# and the other two were Ubuntu 16.04 from 2016. Refresh with:
#   aws ssm get-parameter --region <region> --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --query Parameter.Value --output text
variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0d6dd9e8265d48906"
    us-west-2 = "ami-08cf17e3856f70154"
    eu-west-1 = "ami-0445442ed20a2c6f8"
  }
}

# Where SSH (for the remote-exec provisioner) is allowed from. Narrow it to your own address: "1.2.3.4/32".
variable "SSH_CIDR" {
  default = "0.0.0.0/0"
}
