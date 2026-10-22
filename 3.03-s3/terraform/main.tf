# 3.05 Amazon S3 – the result of LAB 1 + LAB 2 as code:
# bucket + versioning + public read access + static website + index.html

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

# bucket_prefix lets AWS add a unique suffix (bucket names are global)
resource "aws_s3_bucket" "site" {
  bucket_prefix = "jblabs-"
  force_destroy = true # allows "terraform destroy" to delete a non-empty bucket
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# LAB 2, Part A step 2: turn off Block Public Access for this bucket
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# LAB 2, Part A step 3: public read bucket policy
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })

  # the policy is rejected while Block Public Access is still on
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# LAB 2, step 9 (bonus): static website hosting
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  index_document {
    suffix = "index.html"
  }
}

# LAB 2, Part B: upload the example page
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/../artifacts/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../artifacts/index.html")
}

output "bucket_name" {
  value = aws_s3_bucket.site.id
}

output "object_url" {
  value = "https://${aws_s3_bucket.site.bucket_regional_domain_name}/${aws_s3_object.index.key}"
}

output "website_endpoint" {
  value = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}
