provider "aws" {
  region = "eu-west-1"

  ## Begin LocalStack
  #access_key                  = "anaccesskey"
  #secret_key                  = "asecretkey"
  #s3_use_path_style           = true # Enable path-style URLs for S3
  #skip_credentials_validation = true # Skip AWS credentials validation
  #skip_metadata_api_check     = true # Skip checking the instance metadata service
  #skip_requesting_account_id  = true # Skip requesting the account ID

  #endpoints {
  #  ec2 = "http://localhost:4566"
  #  sts = "http://localhost:4566"
  #  s3  = "http://localhost:4566"
  #}
  ## End LocalStack
}
