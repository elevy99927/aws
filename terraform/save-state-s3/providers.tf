provider "aws" {
  region = "us-west-2"

  access_key                  = "anaccesskey"
  secret_key                  = "asecretkey"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}
