#vars.tf
variable "AWS_REGION" {
  type    = string
  default = "eu-west-1"
}

# Step 1: AMIs map
variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-0d729a60" # <-- intentionally wrong per the exercise
  }
}

# Bucket name must be globally unique in S3
variable "bucket_name" {
  type    = string
  default = "yourname-bucket"
}

