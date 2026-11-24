# Two execution roles, one per function. Both trust Lambda and can write logs.
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "writer" {
  name               = "${var.lab_name}-writer"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role" "reader" {
  name               = "${var.lab_name}-reader"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

resource "aws_iam_role_policy_attachment" "writer_logs" {
  role       = aws_iam_role.writer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "reader_logs" {
  role       = aws_iam_role.reader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The writer may only PutItem, the reader may only Scan, and only on this table.
resource "aws_iam_role_policy" "catalog_write" {
  name = "catalog-write"
  role = aws_iam_role.writer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:PutItem"
      Resource = aws_dynamodb_table.catalog.arn
    }]
  })
}

resource "aws_iam_role_policy" "catalog_read" {
  name = "catalog-read"
  role = aws_iam_role.reader.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "dynamodb:Scan"
      Resource = aws_dynamodb_table.catalog.arn
    }]
  })
}
