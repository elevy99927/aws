terraform {
  backend "s3" {
    bucket         = "tfstate-<yourname>-<number>"
    key            = "tf-lab-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock"
  }
}
