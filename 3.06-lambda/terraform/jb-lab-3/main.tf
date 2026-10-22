# jb-lab-3 – limits and pricing: the benchmark function, with memory and timeout as variables
#   terraform apply -var memory=1024 -var timeout=10

terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "memory" {
  description = "Memory in MB (128 - 10240). CPU is allocated in proportion."
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Timeout in seconds (1 - 900)"
  type        = number
  default     = 3
}

resource "aws_iam_role" "lambda" {
  name = "lab-jb3-role"
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
  name              = "/aws/lambda/jb-lab-3-benchmark"
  retention_in_days = 7
}

data "archive_file" "code" {
  type        = "zip"
  source_file = "${path.module}/../../artifacts/jb-lab-3/lambda_function.py"
  output_path = "${path.module}/build/jb-lab-3.zip"
}

resource "aws_lambda_function" "benchmark" {
  function_name    = "jb-lab-3-benchmark"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.code.output_path
  source_code_hash = data.archive_file.code.output_base64sha256
  memory_size      = var.memory
  timeout          = var.timeout

  depends_on = [aws_iam_role_policy_attachment.logs, aws_cloudwatch_log_group.lambda]
}
