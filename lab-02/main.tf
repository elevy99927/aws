# --- EC2 #1 ---
resource "aws_instance" "micro_t2" {
  # Pick AMI based on region
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"

  tags = {
    Name = "micro-t2"
  }
}

# --- EC2 #2 ---
resource "aws_instance" "micro_t3" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t3.micro"

  tags = {
    Name = "micro-t3"
  }
}

# --- S3 Bucket (private) ---
resource "aws_s3_bucket" "private_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "my-private-bucket"
  }
}

# Many AWS provider versions manage ACL via a separate resource
resource "aws_s3_bucket_acl" "private_acl" {
  bucket = aws_s3_bucket.private_bucket.id
  acl    = "private"
}

