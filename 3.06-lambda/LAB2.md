# 3.06 Serverless: AWS Lambda – LAB 2

[⬅ Back to 3.06 AWS Lambda](README.md) | [Lab 2 Solution ➡](SOLUTION-LAB2.md)

---

## 🧪 LAB 2 (Advanced): S3 Upload → Lambda "Scanner" → Clean Bucket

> ⚠️ **Advanced lab:** this lab may not work in every AWS account because of SCPs (Service Control Policies) or other restrictions, for example in a classroom account. We recommend doing it in your own private AWS account.

> 🏫 **Classroom account:** Lambda and CloudWatch Logs are blocked in the classroom account, so this lab can't run there.

> 💰 **Cost:** effectively **$0**. Lambda stays inside the Free Tier, and a few small S3 objects cost fractions of a cent. Delete the buckets at the end anyway.

**Goal:** Build an **event-driven pipeline**. When a file is uploaded to an `upload` bucket, S3 sends an **event** that **triggers** a Lambda function. The function "scans" the file (it only prints `scanning ...`) and copies it to a `clean` bucket.

```
  aws s3 cp file.txt          S3 event: ObjectCreated            copy_object
 ───────────────────► [ upload bucket ] ──────────────────► λ lab-scanner ──────────────► [ clean bucket ]
                                                                  │
                                                                  └─ print("scanning ...") ─► CloudWatch Logs
```

**Prerequisites:**
- [LAB 1](README.md#-lab-1-advanced-your-first-lambda-function): creating and testing a Lambda function.
- [3.03 Amazon S3](../3.03-s3/README.md): buckets and objects.
- [2.02 IAM](../2.02-iam/README.md): roles and policies.

**Tools:** Console + AWS CLI. Region: `us-east-1`. The code is in [`artifacts/scanner/lambda_function.py`](artifacts/scanner/lambda_function.py):

```python
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
```

---

## Background: How the Pieces Fit

| Piece | Role in the pipeline |
|-------|----------------------|
| **S3 event notification** | Configured on the `upload` bucket. "On every `s3:ObjectCreated:*`, invoke `lab-scanner`." |
| **Lambda resource-based policy** | Permission **on the function** that allows `s3.amazonaws.com` to invoke it, but only for **your** upload bucket. The Console adds it for you when you add a trigger |
| **Execution role** | Permission **for the function's code**: write logs, **read** from `upload`, **write** to `clean`. Nothing more (least privilege) |
| **Environment variable `CLEAN_BUCKET`** | Tells the code where to copy files, so the same code works with any bucket name |
| **Asynchronous invocation** | S3 doesn't wait for the function. If the function fails, Lambda **retries twice** |

> ⚠️ **Never write to the same bucket that triggers the function.** Each copy would create a new object, which triggers the function again, which creates another copy, and so on: an **infinite loop** with a growing bill. That's why this lab uses **two** buckets. Lambda can detect and stop some recursive loops, but don't rely on it.

---

## Tasks

**Part A: Two buckets**

1. Create two buckets in `us-east-1` with the same unique suffix, for example:
   - `lab-upload-<your-name>-<random>`
   - `lab-clean-<your-name>-<random>`

**Part B: Execution role (least privilege)**

2. In **IAM → Roles → Create role**, choose trusted entity **AWS service → Lambda**, attach the AWS managed policy **`AWSLambdaBasicExecutionRole`**, and name the role `lab-scanner-role`.
3. Add an **inline policy** named `lab-scanner-s3` to the role that allows **only**:
   - `s3:GetObject` on objects in the **upload** bucket
   - `s3:PutObject` on objects in the **clean** bucket

**Part C: The function**

4. Create a function `lab-scanner`: **Python 3.14**, execution role **Use an existing role → `lab-scanner-role`**.
5. Deploy the scanner code above.
6. Add an environment variable `CLEAN_BUCKET` = the name of **your clean bucket**.
7. In **Configuration → General configuration**, set the **timeout** to **30 seconds**. The default of 3 seconds is too short for a cold start plus an S3 copy.

**Part D: The trigger**

8. In the function overview, choose **Add trigger → S3**:
   - Bucket: **your upload bucket**
   - Event types: **All object create events**
   - Check the **Recursive invocation** acknowledgment if the Console requires it. Our output goes to a different bucket, so there's no loop.

**Part E: Test**

9. Upload two files to the **upload** bucket. One of them should have a **space** in its name and be inside a "folder":
   ```bash
   echo "invoice 2026"   > invoice.txt
   echo "monthly report" > "my report.txt"
   aws s3 cp invoice.txt     s3://<upload-bucket>/invoice.txt
   aws s3 cp "my report.txt" "s3://<upload-bucket>/reports/my report.txt"
   ```
10. After a few seconds, list the **clean** bucket. Both files should be there, with the same keys.
11. Open the function's **CloudWatch logs** and find the `scanning ...`, `scan result` and `copied to` lines for each file.

**Part F: Clean up**

12. Delete the trigger (or the whole function), both buckets with their objects, the function `lab-scanner`, its log group, and the role `lab-scanner-role`.

---

## Questions

- What would happen if `CLEAN_BUCKET` pointed to the **upload** bucket?
- Why does the code call `urllib.parse.unquote_plus()` on the key? What breaks without it?
- The function has **two** kinds of permissions: the execution role and the resource-based policy. Which one allows S3 to *call* the function, and which one allows the function to *read and write* S3?
- S3 invokes Lambda **asynchronously**. What happens if the copy fails, for example because the role lacks `s3:PutObject`?
- The lab **copies** the file. What would you add to the code and to the role to **move** it instead?

---

[⬅ Back to 3.06 AWS Lambda](README.md) | [Lab 2 Solution ➡](SOLUTION-LAB2.md)
