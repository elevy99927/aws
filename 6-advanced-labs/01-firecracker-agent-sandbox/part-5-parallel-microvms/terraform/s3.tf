# The results bucket: <repo>/pr-<n>/<sha>/ holds the three reports and summary.json of one scan.
# force_destroy: the results are lab output, so destroy empties the bucket instead of failing on it.
resource "aws_s3_bucket" "results" {
  bucket_prefix = "fc-agents-results-"
  force_destroy = true
}
