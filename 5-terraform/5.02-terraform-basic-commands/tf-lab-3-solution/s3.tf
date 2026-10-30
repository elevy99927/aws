# Bucket names are global across all AWS accounts: replace "yourname" with your own name, in lowercase,
# and 1234 with a random number.
resource "aws_s3_bucket" "lab" {
  bucket = "s3-lab-yourname-1234"
}
