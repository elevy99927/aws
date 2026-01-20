#variable "AWS_ACCESS_KEY" {}
#variable "AWS_SECRET_KEY" {}
#variable "AWS_SESSION_TOKEN" {}


variable "AWS_REGION" {
    default = "eu-west-1"
}

# The AMIS map will be used to match the correct AMI base on the region we operate.
variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-047bb4163c506cd98"
  }
}
