# New in Lab 5: the state lives in S3, not in this folder.
# The bucket must exist before terraform init (create it with the AWS CLI), and a backend block can't use variables.
terraform {
  backend "s3" {
    bucket       = "tfstate-yourname-1234"
    key          = "tf-lab-5/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # a lock file next to the state, while a command runs
  }
}
