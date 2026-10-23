export AWS_PAGER="" AWS_REGION=us-east-1

aws lambda invoke --function-name lab-hello \
  --cli-binary-format raw-in-base64-out \
  --payload '{"name": "CLI"}' \
  --log-type Tail out.json \
  --query LogResult --output text | base64 --decode      # the last 4 KB of the log
cat out.json
