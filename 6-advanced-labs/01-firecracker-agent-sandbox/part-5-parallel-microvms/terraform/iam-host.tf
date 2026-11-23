# The host's role: Systems Manager can reach it (SSM core), it can put results into the bucket and read the
# GitHub token, and it can't read the webhook secret. The guest can't use it: host-net.sh drops guest traffic to
# 169.254.169.254, and the metadata hop limit is 1 (instance.tf).
data "aws_caller_identity" "me" {}

resource "aws_iam_role" "host" {
  name = "fc-agents-host"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "host_ssm" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "host" {
  name = "results-and-token"
  role = aws_iam_role.host.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "s3:PutObject", Resource = "${aws_s3_bucket.results.arn}/*" },
      { Effect = "Allow", Action = "ssm:GetParameter", Resource = "arn:aws:ssm:${var.AWS_REGION}:${data.aws_caller_identity.me.account_id}:parameter/fc/github-token" },
      # AmazonSSMManagedInstanceCore allows ssm:GetParameter(s) on every parameter, and the default aws/ssm key
      # decrypts for the whole account. So the webhook secret, which only the Lambda needs, is denied explicitly.
      { Effect = "Deny", Action = "ssm:GetParameter*", Resource = "arn:aws:ssm:${var.AWS_REGION}:${data.aws_caller_identity.me.account_id}:parameter/fc/webhook-secret" },
    ]
  })
}

resource "aws_iam_instance_profile" "host" {
  name = "fc-agents-host"
  role = aws_iam_role.host.name
}
