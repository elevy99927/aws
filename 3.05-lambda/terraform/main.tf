# 3.11 Serverless: AWS Lambda – LAB 1 + LAB 2 as code
#   LAB 1: lab-hello   – a simple function with a GREETING environment variable
#   LAB 2: lab-scanner – triggered by uploads to the "upload" bucket, copies files to the "clean" bucket
#
# Terraform is taught later in the course. This file is here as a reference.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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

data "aws_caller_identity" "current" {}

# Trust policy shared by both functions: "the Lambda service may assume this role"
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# =====================================================================
# LAB 1: lab-hello
# =====================================================================

resource "aws_iam_role" "hello" {
  name               = "lab-lambda-hello-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "hello_logs" {
  role       = aws_iam_role.hello.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "hello" {
  type        = "zip"
  source_file = "${path.module}/../artifacts/hello/lambda_function.py"
  output_path = "${path.module}/build/hello.zip"
}

# Managing the log group in Terraform means "terraform destroy" deletes the logs too
resource "aws_cloudwatch_log_group" "hello" {
  name              = "/aws/lambda/lab-hello"
  retention_in_days = 7
}

resource "aws_lambda_function" "hello" {
  function_name    = "lab-hello"
  role             = aws_iam_role.hello.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.hello.output_path
  source_code_hash = data.archive_file.hello.output_base64sha256

  environment {
    variables = {
      GREETING = "Shalom"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.hello_logs, aws_cloudwatch_log_group.hello]
}

# =====================================================================
# LAB 2: upload bucket -> lab-scanner -> clean bucket
# =====================================================================

resource "aws_s3_bucket" "upload" {
  bucket_prefix = "lab-upload-"
  force_destroy = true
}

resource "aws_s3_bucket" "clean" {
  bucket_prefix = "lab-clean-"
  force_destroy = true
}

resource "aws_iam_role" "scanner" {
  name               = "lab-scanner-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "scanner_logs" {
  role       = aws_iam_role.scanner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least privilege: read only from "upload", write only to "clean"
resource "aws_iam_role_policy" "scanner_s3" {
  name = "lab-scanner-s3"
  role = aws_iam_role.scanner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Sid = "ReadUploads", Effect = "Allow", Action = "s3:GetObject", Resource = "${aws_s3_bucket.upload.arn}/*" },
      { Sid = "WriteCleaned", Effect = "Allow", Action = "s3:PutObject", Resource = "${aws_s3_bucket.clean.arn}/*" },
    ]
  })
}

data "archive_file" "scanner" {
  type        = "zip"
  source_file = "${path.module}/../artifacts/scanner/lambda_function.py"
  output_path = "${path.module}/build/scanner.zip"
}

resource "aws_cloudwatch_log_group" "scanner" {
  name              = "/aws/lambda/lab-scanner"
  retention_in_days = 7
}

resource "aws_lambda_function" "scanner" {
  function_name    = "lab-scanner"
  role             = aws_iam_role.scanner.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  timeout          = 30
  filename         = data.archive_file.scanner.output_path
  source_code_hash = data.archive_file.scanner.output_base64sha256

  environment {
    variables = {
      CLEAN_BUCKET = aws_s3_bucket.clean.bucket
    }
  }

  depends_on = [aws_iam_role_policy_attachment.scanner_logs, aws_cloudwatch_log_group.scanner]
}

# Resource-based policy on the function: S3 (only this bucket, only this account) may invoke it
resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "s3-invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.scanner.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.upload.arn
  source_account = data.aws_caller_identity.current.account_id
}

# The trigger: every new object in "upload" invokes lab-scanner
resource "aws_s3_bucket_notification" "upload" {
  bucket = aws_s3_bucket.upload.id

  lambda_function {
    id                  = "scan-new-uploads"
    lambda_function_arn = aws_lambda_function.scanner.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# ---------- Outputs ----------

output "upload_bucket" {
  value = aws_s3_bucket.upload.bucket
}

output "clean_bucket" {
  value = aws_s3_bucket.clean.bucket
}

output "try_it" {
  value = <<-EOT
    aws lambda invoke --function-name lab-hello --cli-binary-format raw-in-base64-out --payload '{"name": "Student"}' out.json && cat out.json
    aws s3 cp <any-file> s3://${aws_s3_bucket.upload.bucket}/ && sleep 5 && aws s3 ls s3://${aws_s3_bucket.clean.bucket}/
  EOT
}
