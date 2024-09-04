terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}


data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.file_name
  output_path = var.lambda_name
}

resource "aws_lambda_function" "lambda" {
  filename      = var.zip_file
  function_name = var.lambda_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime = var.runtime

  timeout = 15
  #memory_size = 2048
  environment {
    variables = {
      PRODUCTION = false      
      #### For S3 Integration ####
      S3_BUCKET = aws_s3_bucket.s3_unencrypted.id
    }
  }
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "my-first-tf-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda" {
  name = "lambda-permissions"
  role = aws_iam_role.lambda_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_lambda_function_url" "lambda" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}

output "function_url" {
  value = aws_lambda_function_url.lambda.function_url
}



#############################
# Add S3 integration
#############################
# Unencrypted S3 bucket
resource "aws_s3_bucket" "s3_unencrypted" {
  bucket = "pk-test-not-encrypted-bucket"
}


# IAM Role for the unencrypted Lambda
resource "aws_iam_role" "iam_lambda_unencrypted" {
  name = "pk-test-lambda-unencrypted"

  managed_policy_arns = [
    aws_iam_policy.lambda_s3_policy.arn,
  ]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# S3 Policy for Lambda
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "pk-test-lambda-s3-policy"
  path        = "/"
  description = "Access to s3 buckets"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "S3:PutObject",
        ],
        "Resource" : [
          "${aws_s3_bucket.s3_unencrypted.arn}",
          "${aws_s3_bucket.s3_unencrypted.arn}/*",
        ]
      }
    ]
  })
}


