import json
import os
from urllib.parse import unquote_plus

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    recorded = 0
    for record in event.get("Records", []):
        if record.get("eventSource") != "aws:s3":
            continue
        bucket = record["s3"]["bucket"]["name"]
        # S3 sends the key URL-encoded: "daily report.txt" arrives as "daily+report.txt"
        key = unquote_plus(record["s3"]["object"]["key"])
        table.put_item(Item={
            "bucket_name": bucket,
            "object_key": key,
            "event_time": record["eventTime"],
        })
        print(json.dumps({"bucket": bucket, "key": key}))
        recorded += 1
    return {"recorded": recorded}
