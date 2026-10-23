# jb-lab-2 – S3 image upload -> Lambda -> thumbnail, as code
# Build the deployment package first:  bash ../../artifacts/jb-lab-2/build.sh

terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "images" {
  bucket_prefix = "jblabs-images-"
  force_destroy = true
}

resource "aws_s3_bucket" "thumbnails" {
  bucket_prefix = "jblabs-thumbnails-"
  force_destroy = true
}

resource "aws_iam_role" "lambda" {
  name = "lab-jb2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least privilege: read originals, write thumbnails
resource "aws_iam_role_policy" "s3" {
  name = "lab-jb2-s3"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "s3:GetObject", Resource = "${aws_s3_bucket.images.arn}/*" },
      { Effect = "Allow", Action = "s3:PutObject", Resource = "${aws_s3_bucket.thumbnails.arn}/*" },
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/jb-lab-2-thumbnailer"
  retention_in_days = 7
}

resource "aws_lambda_function" "thumbnailer" {
  function_name    = "jb-lab-2-thumbnailer"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = "${path.module}/../../artifacts/jb-lab-2/function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../artifacts/jb-lab-2/function.zip")
  memory_size      = 512
  timeout          = 30

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.thumbnails.bucket
      MAX_SIZE    = "200"
    }
  }

  depends_on = [aws_iam_role_policy_attachment.logs, aws_cloudwatch_log_group.lambda]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id   = "s3-invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.thumbnailer.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.images.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "images" {
  bucket = aws_s3_bucket.images.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.thumbnailer.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

output "images_bucket" {
  value = aws_s3_bucket.images.bucket
}

output "thumbnails_bucket" {
  value = aws_s3_bucket.thumbnails.bucket
}
