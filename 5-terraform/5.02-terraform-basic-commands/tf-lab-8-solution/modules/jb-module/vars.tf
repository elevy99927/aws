variable "region" {
  type = string
  default = "us-east-1"
} # The following are standard variables for input
variable "size" {}
variable "number-instances" {}



variable "AWS_REGION" {
  default = "us-east-1"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-0d97d7f07b25dd693"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-047bb4163c506cd98"
  }
}