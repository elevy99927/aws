# jb-lab-1 – Lambda runs functions: the function from the lab, as code

terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda" {
  name = "lab-jb1-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/jb-lab-1"
  retention_in_days = 7
}

data "archive_file" "code" {
  type        = "zip"
  source_file = "${path.module}/../../artifacts/jb-lab-1/lambda_function.py"
  output_path = "${path.module}/build/jb-lab-1.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "jb-lab-1"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.logs, aws_cloudwatch_log_group.lambda]
}

output "try_it" {
  value = "aws lambda invoke --function-name jb-lab-1 --cli-binary-format raw-in-base64-out --payload file://../../artifacts/jb-lab-1/events/add.json out.json && cat out.json"
}
