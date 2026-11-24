# Part 2: the catalog table. One row per bucket + object key.
resource "aws_dynamodb_table" "catalog" {
  name         = var.lab_name
  billing_mode = "PAY_PER_REQUEST" # On-demand
  hash_key     = "bucket_name"     # partition key
  range_key    = "object_key"      # sort key

  attribute {
    name = "bucket_name"
    type = "S"
  }

  attribute {
    name = "object_key"
    type = "S"
  }
}

# Part 3: the bucket that receives the files. New buckets block public access by default.
resource "aws_s3_bucket" "files" {
  bucket        = var.lab_name
  force_destroy = true # lets "terraform destroy" delete a bucket that still has test files
}
