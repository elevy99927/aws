output "bucket_name" {
  value = aws_s3_bucket.files.bucket
}

output "table_name" {
  value = aws_dynamodb_table.catalog.name
}

output "report_url" {
  description = "Open this in a browser to see the report"
  value       = aws_lambda_function_url.reader.function_url
}
