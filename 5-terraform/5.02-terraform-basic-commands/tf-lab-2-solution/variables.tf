variable "region" {
  description = "AWS Region for the instance"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability Zone for the instance (its default subnet in the default VPC)"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
