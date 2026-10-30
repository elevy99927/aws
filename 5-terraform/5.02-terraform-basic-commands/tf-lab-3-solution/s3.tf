# Bucket names are global across all AWS accounts: replace "yourname" with your own name, in lowercase.
resource "aws_s3_bucket" "lab" {
  bucket = "s3-lab-yourname"
}
