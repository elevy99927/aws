# The state lives in S3, and a DynamoDB table holds the lock. The bucket and the table are created with the AWS CLI,
# before terraform init: a backend block can't use variables, and Terraform can't manage the bucket that stores its own state.
terraform {
  backend "s3" {
    bucket         = "tfstate-yourname-1234"
    key            = "tf-lab-5/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock"
  }
}
