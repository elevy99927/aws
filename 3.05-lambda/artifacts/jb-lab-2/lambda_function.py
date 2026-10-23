import io
import os
import urllib.parse

import boto3
from PIL import Image, UnidentifiedImageError

s3 = boto3.client("s3")
DEST_BUCKET = os.environ["DEST_BUCKET"]
MAX_SIZE = int(os.environ.get("MAX_SIZE", "200"))


def lambda_handler(event, context):
    for record in event["Records"]:
        source_bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])
        print(f"processing s3://{source_bucket}/{key}")

        body = s3.get_object(Bucket=source_bucket, Key=key)["Body"].read()
        try:
            image = Image.open(io.BytesIO(body))
        except UnidentifiedImageError:
            print(f"skipping {key}: not an image")
            continue

        image_format = image.format              # e.g. JPEG, PNG
        original_size = image.size
        image.thumbnail((MAX_SIZE, MAX_SIZE))    # keeps the aspect ratio

        out = io.BytesIO()
        image.save(out, format=image_format)
        s3.put_object(
            Bucket=DEST_BUCKET,
            Key=key,
            Body=out.getvalue(),
            ContentType=Image.MIME.get(image_format, "application/octet-stream"),
        )
        print(f"resized {original_size} -> {image.size}, saved to s3://{DEST_BUCKET}/{key}")

    return {"status": "ok", "files": len(event["Records"])}
