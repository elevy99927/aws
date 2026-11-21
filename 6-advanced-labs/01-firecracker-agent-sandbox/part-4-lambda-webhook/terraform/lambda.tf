# The webhook: a Lambda with a public Function URL. Auth NONE because GitHub can't sign AWS requests; the
# signature check in app.py is the gate. With NONE, this resource adds the two public permissions itself
# (InvokeFunctionUrl, and InvokeFunction via the URL), and destroy does not remove them: they go with the function.
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/app.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda" {
  name = "fc-agents-webhook"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SendCommand on exactly this host and this document; the webhook secret, nothing else.
resource "aws_iam_role_policy" "lambda" {
  name = "send-one-command"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "ssm:SendCommand", Resource = [aws_instance.host.arn, aws_ssm_document.pr_job.arn] },
      { Effect = "Allow", Action = "ssm:GetParameter", Resource = "arn:aws:ssm:${var.AWS_REGION}:${data.aws_caller_identity.me.account_id}:parameter/fc/webhook-secret" },
    ]
  })
}

resource "aws_lambda_function" "webhook" {
  function_name    = "fc-agents-webhook"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.14"
  handler          = "app.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30
  environment {
    variables = {
      HOST         = aws_instance.host.id
      DOCUMENT     = aws_ssm_document.pr_job.name
      REPOS        = var.REPOS
      SECRET_PARAM = "/fc/webhook-secret"
    }
  }
}

resource "aws_lambda_function_url" "webhook" {
  function_name      = aws_lambda_function.webhook.function_name
  authorization_type = "NONE"
}
