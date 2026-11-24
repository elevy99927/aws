import html
import os

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    # Scan reads the whole table, one page (up to 1 MB) at a time
    items = []
    page = table.scan()
    items.extend(page["Items"])
    while "LastEvaluatedKey" in page:
        page = table.scan(ExclusiveStartKey=page["LastEvaluatedKey"])
        items.extend(page["Items"])

    columns = ("bucket_name", "object_key", "event_time")
    rows = []
    for item in sorted(items, key=lambda item: (item["bucket_name"], item["object_key"])):
        cells = "".join(f"<td>{html.escape(item[column])}</td>" for column in columns)
        rows.append(f"<tr>{cells}</tr>")
    body = (
        '<!doctype html><html lang="en"><meta charset="utf-8">'
        '<title>Uploaded files</title>'
        '<style>body{font-family:sans-serif;margin:2rem}table{border-collapse:collapse}'
        'th,td{border:1px solid #999;padding:.4rem .8rem;text-align:left}th{background:#eee}</style>'
        '<h1>Uploaded files</h1>'
        f'<p>{len(items)} recorded objects</p>'
        '<table><thead><tr><th>Bucket</th><th>Object key</th><th>S3 event time (UTC)</th>'
        '</tr></thead><tbody>' + "".join(rows) + '</tbody></table></html>'
    )
    # A function URL turns this dictionary into an HTTP response
    return {"statusCode": 200, "headers": {"Content-Type": "text/html; charset=utf-8"}, "body": body}
