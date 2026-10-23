import json
import os


def lambda_handler(event, context):
    # GREETING comes from an environment variable (Lab 1, Part D); default "Hello"
    greeting = os.environ.get("GREETING", "Hello")
    name = event.get("name", "World")
    message = f"{greeting}, {name}!"

    # print() goes to CloudWatch Logs
    print(f"request_id={context.aws_request_id} message={message}")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": message}),
    }
