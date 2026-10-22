import os
import urllib.parse

import boto3

s3 = boto3.client("s3")
CLEAN_BUCKET = os.environ["CLEAN_BUCKET"]


def lambda_handler(event, context):
    # One S3 event can contain several records (files)
    for record in event["Records"]:
        source_bucket = record["s3"]["bucket"]["name"]
        # Keys arrive URL-encoded: "my file.txt" -> "my+file.txt"
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        print(f"scanning s3://{source_bucket}/{key} ...")
        print("scan result: CLEAN")  # a real scanner (antivirus, DLP) would run here

        s3.copy_object(
            Bucket=CLEAN_BUCKET,
            Key=key,
            CopySource={"Bucket": source_bucket, "Key": key},
        )
        print(f"copied to s3://{CLEAN_BUCKET}/{key}")

    return {"status": "ok", "files": len(event["Records"])}
