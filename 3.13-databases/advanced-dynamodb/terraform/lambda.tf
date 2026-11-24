# The same handlers as the Console parts, zipped from ../lambda-code
data "archive_file" "writer" {
  type        = "zip"
  source_file = "${path.module}/../lambda-code/writer/lambda_function.py"
  output_path = "${path.module}/build/writer.zip"
}

data "archive_file" "reader" {
  type        = "zip"
  source_file = "${path.module}/../lambda-code/reader/lambda_function.py"
  output_path = "${path.module}/build/reader.zip"
}

# Managing the log groups lets "terraform destroy" delete the logs too
resource "aws_cloudwatch_log_group" "writer" {
  name              = "/aws/lambda/${var.lab_name}-writer"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "reader" {
  name              = "/aws/lambda/${var.lab_name}-reader"
  retention_in_days = 7
}

# Part 3: the writer, triggered by S3
resource "aws_lambda_function" "writer" {
  function_name    = "${var.lab_name}-writer"
  role             = aws_iam_role.writer.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.writer.output_path
  source_code_hash = data.archive_file.writer.output_base64sha256

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.catalog.name }
  }

  depends_on = [aws_cloudwatch_log_group.writer, aws_iam_role_policy_attachment.writer_logs]
}

# S3 needs permission to invoke the writer. The Console adds this for you.
resource "aws_lambda_permission" "s3_invoke_writer" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.writer.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.files.arn
  source_account = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

# The S3 trigger: every object created under incoming/
resource "aws_s3_bucket_notification" "incoming" {
  bucket = aws_s3_bucket.files.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.writer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
  }

  # S3 tests the invoke permission when the notification is saved
  depends_on = [aws_lambda_permission.s3_invoke_writer]
}

# Part 4: the reader, behind a public Function URL
resource "aws_lambda_function" "reader" {
  function_name    = "${var.lab_name}-reader"
  role             = aws_iam_role.reader.arn
  runtime          = "python3.14"
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.reader.output_path
  source_code_hash = data.archive_file.reader.output_base64sha256

  environment {
    variables = { TABLE_NAME = aws_dynamodb_table.catalog.name }
  }

  depends_on = [aws_cloudwatch_log_group.reader, aws_iam_role_policy_attachment.reader_logs]
}

resource "aws_lambda_function_url" "reader" {
  function_name      = aws_lambda_function.reader.function_name
  authorization_type = "NONE" # public: anyone with the URL can read the report
}

# A public URL needs two statements in the function's resource policy:
# lambda:InvokeFunctionUrl, which AWS adds when you create a URL with auth NONE,
# and lambda:InvokeFunction for calls through the URL, which we add here.
# (The Console adds both for you.)
resource "aws_lambda_permission" "url_invoke" {
  statement_id             = "FunctionURLAllowInvokeAction"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.reader.function_name
  principal                = "*"
  invoked_via_function_url = true
}
