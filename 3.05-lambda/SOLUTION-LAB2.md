# 3.05 Serverless: AWS Lambda – Lab 2 Solution

[⬅ Lab 2](LAB2.md) | [⬅ Back to 3.05 AWS Lambda](README.md)

> Tested in `us-east-1` with the **Python 3.14** runtime: the Console on 2026-10-24, the CLI with AWS CLI v2.

---

## LAB 2 (Advanced): S3 Upload → Lambda "Scanner" → Clean Bucket

**Jump to:** [Solution 1: Console](#solution-1-console-ui) · [Solution 2: AWS CLI](#solution-2-aws-cli) · [Answers](#answers)

## Solution 1: Console (UI)

> Tested in `us-east-1` on 2026-10-24 with the current Console (**Create Event Function**). The bucket suffix in the screenshots is `7421093`; use your own.

### Part A: Two buckets

1. Open **S3 → Buckets** and choose **Create bucket**. (Filtering the list with `lab-` shows only this lab's buckets.)

   ![S3 – Buckets – Create bucket](images/lab2-01-s3-create-bucket.jpg)

2. Keep **General purpose** and **Global namespace**, and enter the name `lab-upload-<suffix>`.

   ![Create bucket – lab-upload-<suffix>](images/lab2-02-upload-bucket-name.jpg)

3. Keep the defaults (Block all public access, SSE-S3 encryption) and choose **Create bucket** at the bottom.

   ![Create bucket button](images/lab2-03-create-bucket-button.jpg)

4. Create the second bucket the same way, named `lab-clean-<suffix>`, with the same suffix.

   ![Create bucket – lab-clean-<suffix>](images/lab2-04-clean-bucket-name.jpg)

5. Both buckets are in `us-east-1`.

   ![Two buckets: lab-clean and lab-upload](images/lab2-05-two-buckets.jpg)

### Part B: Execution role (least privilege)

6. Open **IAM → Roles** and choose **Create role**.

   ![IAM – Roles – Create role](images/lab2-06-iam-create-role.jpg)

7. Trusted entity type **AWS service**, service or use case **Lambda**.

   ![Trusted entity: AWS service – Lambda](images/lab2-07-trusted-entity-lambda.jpg)

8. Search for **`AWSLambdaBasicExecutionRole`**, filter by type **AWS managed**, and check it. It lets the function write its logs.

   ![AWSLambdaBasicExecutionRole selected](images/lab2-08-basic-execution-policy.jpg)

9. Name the role **`lab-scanner-role`**. The trust policy shows that only `lambda.amazonaws.com` can assume it. Choose **Create role**.

   ![Role name lab-scanner-role and trust policy](images/lab2-09-role-name-trust.jpg)

10. Open the new role and choose **Add permissions → Create inline policy**.

    ![Add permissions – Create inline policy](images/lab2-10-create-inline-policy.jpg)

11. Switch to **JSON** and paste the policy, with your bucket names:

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        { "Sid": "ReadUploads",  "Effect": "Allow", "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::lab-upload-<suffix>/*" },
        { "Sid": "WriteCleaned", "Effect": "Allow", "Action": "s3:PutObject",
          "Resource": "arn:aws:s3:::lab-clean-<suffix>/*" }
      ]
    }
    ```

    ![Inline policy JSON: GetObject on upload, PutObject on clean](images/lab2-11-inline-policy-json.jpg)

12. Name it **`lab-scanner-s3`**. The summary shows S3 with access level **Limited: Read, Write**. Choose **Create policy**.

    ![Policy name lab-scanner-s3 – Limited: Read, Write](images/lab2-12-inline-policy-name.jpg)

13. The role has two policies: the AWS managed one for logs, and the inline one for the two buckets.

    ![lab-scanner-role with two policies](images/lab2-13-role-two-policies.jpg)

> `copy_object` needs **`s3:GetObject` on the source** and **`s3:PutObject` on the destination**. The function can't list, delete or touch any other bucket.

### Part C: The function

14. Open **Lambda → Create function**. Choose **Author from scratch**, name **`lab-scanner`**, runtime **Python 3.14**.

    ![Create Event Function – lab-scanner, Python 3.14](images/lab2-14-create-function.jpg)

15. Expand **Additional settings**, turn on **Custom execution role**, choose **`lab-scanner-role`** and **Save**. Then choose **Create Event Function**.

    ![Custom execution role – lab-scanner-role](images/lab2-15-custom-execution-role.jpg)

16. The function is created, still with the Hello World code.

    ![Function lab-scanner created](images/lab2-16-function-created.jpg)

17. In **Code source**, replace the code with [`lambda_function.py`](artifacts/scanner/lambda_function.py) and choose **Deploy**.

    ![Scanner code – Deploy](images/lab2-17-code-deploy.jpg)

18. The status bar shows **Lambda Deployed**.

    ![Successfully updated – Lambda Deployed](images/lab2-18-code-deployed.jpg)

19. Open **Configuration → Environment variables** and choose **Edit**.

    ![Configuration – Environment variables – Edit](images/lab2-19-env-vars-edit.jpg)

20. Add **`CLEAN_BUCKET`** = your clean bucket name, and **Save**.

    ![CLEAN_BUCKET = lab-clean-<suffix>](images/lab2-20-env-var-clean-bucket.jpg)

21. Open **General configuration → Edit**, set **Timeout** to **30 sec**, and **Save**. The default is 3 seconds; 30 seconds leaves room for a slow S3 request.

    ![Timeout 30 sec](images/lab2-21-timeout-30.jpg)

### Part D: The trigger

22. In the function overview, choose **Add trigger**.

    ![Function overview – Add trigger](images/lab2-22-add-trigger.jpg)

23. Source **S3** (note the *asynchronous* tag), bucket **`lab-upload-<suffix>`**, event types **All object create events**.

    ![Trigger: S3, upload bucket, All object create events](images/lab2-23-trigger-s3-config.jpg)

24. The **Recursive invocation** acknowledgment is required. Without it, **Add** fails with *Please acknowledge*. Check it: our output goes to a different bucket, so there's no loop. Then choose **Add**.

    ![Recursive invocation – acknowledgment required](images/lab2-24-recursive-ack-required.jpg)

25. The diagram now shows **S3 → lab-scanner**, and **Configuration → Triggers** lists the upload bucket.

    ![Trigger added: S3 → lab-scanner](images/lab2-25-trigger-added.jpg)

26. Expand **Details**: event type **`s3:ObjectCreated:*`**, service principal **`s3.amazonaws.com`**, and the statement ID of the permission that **Add trigger** created in the function's resource-based policy.

    ![Trigger details: event type, service principal, statement ID](images/lab2-26-trigger-details.jpg)

### Part E: Test

27. Open **CloudShell** (bottom left of the Console), create the two files, upload them, and list the clean bucket:

    ```bash
    echo "invoice 2026"   > invoice.txt
    echo "monthly report" > "my report.txt"
    aws s3 cp invoice.txt s3://lab-upload-<suffix>/invoice.txt
    aws s3 cp "my report.txt" "s3://lab-upload-<suffix>/reports/my report.txt"
    aws s3 ls s3://lab-clean-<suffix> --recursive
    ```

    ![CloudShell: two uploads, both files in the clean bucket](images/lab2-27-cloudshell-upload.jpg)

28. In S3, the clean bucket has `invoice.txt` and the folder `reports/`.

    ![Clean bucket: invoice.txt and reports/](images/lab2-28-clean-bucket.jpg)

29. Inside `reports/` is **`my report.txt`**, the file with a space in its name.

    ![reports/my report.txt](images/lab2-29-clean-reports-folder.jpg)

30. In **CloudWatch → Log groups → `/aws/lambda/lab-scanner`**, open the log stream. Each upload produced its own invocation, with the `scanning`, `scan result` and `copied to` lines. The first was a **cold start** (`INIT_START`, Init Duration about 570 ms). The second reused the warm environment and took about 50 ms.

    ![Scanner logs in CloudWatch](images/lab2-30-scanner-logs.jpg)

### Part F: Clean up

31. In the function, choose **Actions → Delete function**.

    ![Actions – Delete function](images/lab2-31-delete-function.jpg)

32. Type `confirm` and choose **Delete**. The dialog notes that logs, roles and triggers stay in your account, so delete them separately.

    ![Delete function – confirm](images/lab2-32-delete-function-confirm.jpg)

33. In S3, select the upload bucket and choose **Empty**.

    ![S3 – Empty](images/lab2-33-empty-bucket.jpg)

34. Type `permanently delete` and choose **Empty**.

    ![Empty bucket – permanently delete](images/lab2-34-empty-confirm.jpg)

35. Then choose **Delete**, type the bucket name, and choose **Delete bucket**. Repeat steps 33–35 for the clean bucket.

    ![Delete bucket – type the name](images/lab2-35-delete-bucket.jpg)

36. In **CloudWatch → Log groups**, select `/aws/lambda/lab-scanner` and choose **Actions → Delete log group(s)**.

    ![Delete log group](images/lab2-36-delete-log-group.jpg)

37. In **IAM → Roles**, open `lab-scanner-role`, choose **Delete**, type the role name, and choose **Delete**. This also deletes its inline policy.

    ![Delete lab-scanner-role](images/lab2-37-delete-role.jpg)

38. In CloudShell, remove the two local files: `rm -f invoice.txt "my report.txt"`.

---

## Solution 2: AWS CLI

> Run the commands **from the module folder** (`3.05-lambda/`) in one terminal session.

#### Part A: Two buckets

```bash
export AWS_PAGER="" AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

SUFFIX=$RANDOM$RANDOM
UPLOAD_BUCKET=lab-upload-$SUFFIX
CLEAN_BUCKET=lab-clean-$SUFFIX

aws s3 mb s3://$UPLOAD_BUCKET
aws s3 mb s3://$CLEAN_BUCKET
```

```
make_bucket: lab-upload-2570122547
make_bucket: lab-clean-2570122547
```

#### Part B: Execution role (least privilege)

```bash
cat > lambda-trust.json <<'JSON'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
                  "Principal": { "Service": "lambda.amazonaws.com" },
                  "Action": "sts:AssumeRole" }] }
JSON
ROLE_ARN=$(aws iam create-role --role-name lab-scanner-role \
  --assume-role-policy-document file://lambda-trust.json --query Role.Arn --output text)

# 1. Permission to write CloudWatch Logs
aws iam attach-role-policy --role-name lab-scanner-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# 2. Read only from "upload", write only to "clean"
cat > scanner-s3-policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "ReadUploads",  "Effect": "Allow", "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$UPLOAD_BUCKET/*" },
    { "Sid": "WriteCleaned", "Effect": "Allow", "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::$CLEAN_BUCKET/*" }
  ]
}
JSON
aws iam put-role-policy --role-name lab-scanner-role \
  --policy-name lab-scanner-s3 --policy-document file://scanner-s3-policy.json
```

> `copy_object` needs **`s3:GetObject` on the source** and **`s3:PutObject` on the destination**. The function can't list, delete or touch any other bucket.

#### Part C: The function

```bash
sleep 10   # give the new IAM role a few seconds to become usable

(cd artifacts/scanner && zip -q ../../scanner.zip lambda_function.py)

FUNC_ARN=$(aws lambda create-function --function-name lab-scanner \
  --runtime python3.14 --handler lambda_function.lambda_handler \
  --role $ROLE_ARN --zip-file fileb://scanner.zip \
  --timeout 30 \
  --environment "Variables={CLEAN_BUCKET=$CLEAN_BUCKET}" \
  --query FunctionArn --output text)
aws lambda wait function-active-v2 --function-name lab-scanner
```

#### Part D: The trigger

The Console's **Add trigger** does two things for you. With the CLI, you do them yourself:

```bash
# 1. Resource-based policy: allow S3 (only from this bucket and account) to invoke the function
aws lambda add-permission --function-name lab-scanner \
  --statement-id s3-invoke --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::$UPLOAD_BUCKET --source-account $ACCOUNT_ID

# 2. Event notification on the upload bucket
cat > notification.json <<JSON
{
  "LambdaFunctionConfigurations": [{
    "Id": "scan-new-uploads",
    "LambdaFunctionArn": "$FUNC_ARN",
    "Events": ["s3:ObjectCreated:*"]
  }]
}
JSON
aws s3api put-bucket-notification-configuration --bucket $UPLOAD_BUCKET \
  --notification-configuration file://notification.json
```

#### Part E: Test

```bash
echo "invoice 2026"   > invoice.txt
echo "monthly report" > "my report.txt"
aws s3 cp invoice.txt     s3://$UPLOAD_BUCKET/invoice.txt
aws s3 cp "my report.txt" "s3://$UPLOAD_BUCKET/reports/my report.txt"

sleep 5
aws s3 ls s3://$CLEAN_BUCKET --recursive
```

```
2026-10-17 23:30:21         13 invoice.txt
2026-10-17 23:30:21         15 reports/my report.txt
```

**Logs:**

```bash
aws logs filter-log-events --log-group-name /aws/lambda/lab-scanner \
  --query 'events[].message' --output text
```

```
INIT_START Runtime Version: python:3.14.mainline.v75 ...
START RequestId: d60eb18d-... Version: $LATEST
scanning s3://lab-upload-2570122547/invoice.txt ...
scan result: CLEAN
copied to s3://lab-clean-2570122547/invoice.txt
END RequestId: d60eb18d-...
REPORT RequestId: d60eb18d-...  Duration: 357.23 ms  Billed Duration: 897 ms  Memory Size: 128 MB  Max Memory Used: 100 MB  Init Duration: 539.39 ms
START RequestId: 30c1a3dc-... Version: $LATEST
scanning s3://lab-upload-2570122547/reports/my report.txt ...
scan result: CLEAN
copied to s3://lab-clean-2570122547/reports/my report.txt
END RequestId: 30c1a3dc-...
REPORT RequestId: 30c1a3dc-...  Duration: 79.95 ms  Billed Duration: 80 ms  Memory Size: 128 MB  Max Memory Used: 100 MB
```

Each upload produced **its own invocation**. The first one was a **cold start**, and its Init Duration of 539 ms includes importing `boto3`. The second reused the warm environment.

#### Part F: Clean up

```bash
# Remove the trigger first, so emptying the bucket doesn't matter
aws s3api put-bucket-notification-configuration --bucket $UPLOAD_BUCKET \
  --notification-configuration '{}'

aws s3 rb s3://$UPLOAD_BUCKET --force
aws s3 rb s3://$CLEAN_BUCKET --force

aws lambda delete-function --function-name lab-scanner
aws logs delete-log-group --log-group-name /aws/lambda/lab-scanner

aws iam delete-role-policy --role-name lab-scanner-role --policy-name lab-scanner-s3
aws iam detach-role-policy --role-name lab-scanner-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role --role-name lab-scanner-role

rm -f invoice.txt "my report.txt" scanner.zip lambda-trust.json scanner-s3-policy.json notification.json
```

---

## Answers

- **`CLEAN_BUCKET` = the upload bucket:** an **infinite loop**. Every copy is a new object in the upload bucket, which triggers the function again, which copies again, and so on. With this lab's role the first copy would fail anyway, because the role has no `s3:PutObject` on the upload bucket. That's least privilege acting as a safety net. Lambda can also detect some recursive loops and stop them, but the real fix is to **never write to the triggering bucket**, or to filter with a prefix.
- **`unquote_plus()`:** S3 sends object keys **URL-encoded** in the event. `reports/my report.txt` arrives as `reports/my+report.txt`. Without decoding, `copy_object` looks for a key that doesn't exist and fails with `NoSuchKey`.
- **Two kinds of permissions:**
  - The **resource-based policy** on the function lets **S3 call the function**. The CLI names its statement `s3-invoke`; the Console generates a `lambda-…` ID.
  - The **execution role** (`lab-scanner-role`) lets **the function's code** read from `upload` and write to `clean`.
  - You need both. The first controls *who may invoke*, and the second controls *what the code may do*.
- **Failure in an asynchronous invocation:** S3 doesn't see the error, because it doesn't wait. Lambda **retries twice**, with delays, and each attempt logs the `AccessDenied` error to CloudWatch. After that the event is dropped, unless you configure an **on-failure destination** (SQS, SNS, EventBridge, another Lambda) or a **dead-letter queue** to keep failed events.
- **Move instead of copy:** after `copy_object`, call `s3.delete_object(Bucket=source_bucket, Key=key)`, and add **`s3:DeleteObject` on `arn:aws:s3:::<upload-bucket>/*`** to the role.

---

[⬅ Lab 2](LAB2.md) | [⬅ Back to 3.05 AWS Lambda](README.md)
