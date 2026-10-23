# 3.06 Serverless: AWS Lambda

## Topics

- [What is AWS Lambda – serverless, event-driven compute](#1-what-is-aws-lambda)
- [Key concepts – function, handler, event, context, execution role, trigger](#2-key-concepts)
- [Types of Lambda functions – by packaging, by invocation, by where they run](#3-types-of-lambda-functions)
- [ZIP code vs. container image – which to choose](#zip-code-vs-container-image)
- [Cold starts and warm starts](#4-cold-starts-and-warm-starts)
- [Pricing and Free Tier](#5-pricing)
- [Lambda vs. EC2 vs. containers](#6-lambda-vs-ec2-vs-containers)
- [Limits worth knowing](#7-limits-worth-knowing)
- [LAB 1: Your first Lambda function](#-lab-1-advanced-your-first-lambda-function)
- [LAB 2: S3 upload → Lambda "scanner" → clean bucket](LAB2.md)
- [Terraform](#terraform-code)

---

## 1. What is AWS Lambda?

**AWS Lambda** runs your code **without servers that you manage**. You upload a function, and Lambda runs it **when an event happens**: an HTTP request, a file uploaded to S3, a message in a queue, a schedule.

- **No servers to manage:** no OS, no patching, no capacity planning. AWS runs the infrastructure. In the [shared responsibility model](../1.03-shared-responsibility-model/README.md), you are responsible only for **your code, its configuration and its permissions**.
- **Event-driven:** functions run only in response to events, and stop when the work is done.
- **Automatic scaling:** from zero to thousands of parallel executions, with no configuration.
- **Pay per use:** you pay per request and per millisecond of run time. When nothing runs, you pay **nothing**.
- **Runs up to 15 minutes** per invocation. Longer jobs belong on EC2, containers or Step Functions.

Typical uses:

| Use case | Event source |
|----------|--------------|
| Process files as they arrive (resize images, scan documents) | **S3** upload → Lambda ([LAB 2](LAB2.md)) |
| Backend for a web or mobile API | **API Gateway** or a **Function URL** → Lambda |
| Scheduled jobs (cleanup, reports) | **EventBridge Scheduler** (cron) → Lambda |
| Process queue messages | **SQS** → Lambda |
| React to database changes | **DynamoDB Streams** → Lambda |
| Automate AWS operations | **EventBridge** events (for example "EC2 instance stopped") → Lambda |

---

## 2. Key Concepts

```
   Event source                 Lambda function                        Logs
 (S3, API, schedule)  ──event──► handler(event, context) ──print()──► CloudWatch Logs
                                       │
                                       └── uses the execution role (IAM) to call other AWS services
```

| Concept | What it is |
|---------|------------|
| **Function** | Your code plus its configuration: runtime, memory, timeout, environment variables |
| **Runtime** | The language environment: Python, Node.js, Java, .NET, Ruby, or a custom runtime (OS-only) |
| **Handler** | The entry point that Lambda calls, for example `lambda_function.lambda_handler` (file `lambda_function.py`, function `lambda_handler`) |
| **Event** | A JSON document describing what happened, for example which file was uploaded. It's the first argument of the handler |
| **Context** | Runtime information: request ID, remaining time, function name. It's the second argument |
| **Execution role** | The **IAM role** that the function assumes. It defines what the code may do in AWS, for example write logs or read from S3 |
| **Trigger** (event source) | What invokes the function: S3, API Gateway, SQS, EventBridge and more |
| **Environment variables** | Key/value configuration that you can change **without changing the code** |
| **Memory** | 128 MB – 10,240 MB. **CPU is allocated in proportion to memory**, so more memory also means more CPU |
| **Timeout** | Maximum run time per invocation: 3 seconds by default, up to **15 minutes** |
| **Layers** | Shared libraries or dependencies that several functions can reuse |
| **CloudWatch Logs** | Everything the function prints goes to the log group `/aws/lambda/<function-name>` |

---

## 3. Types of Lambda Functions

### By packaging

| Package type | Description |
|--------------|-------------|
| **ZIP archive** (code) | Your code (and dependencies) as a `.zip` file, uploaded directly or from S3. Small functions can be edited in the **Console code editor** |
| **Container image** | A Docker/OCI image stored in **Amazon ECR**, up to **10 GB**. Built on an AWS Lambda base image, or on any image that includes the Lambda runtime interface |

### ZIP code vs. container image

| | ZIP (code) | Container image |
|---|---|---|
| What you need | Just the Console (or a `.zip`) | Docker, an **ECR** repository, build + push, the right CPU architecture |
| Time to the first working function | ~2 minutes | ~15–20 minutes |
| Changing code | Edit in the Console → **Deploy** | Rebuild → push → update the function |
| Maximum size | 50 MB zipped, 250 MB unzipped (including layers) | 10 GB |
| Best for | Small to medium functions, learning, most event processing | Large dependencies (ML models, native libraries), teams that already ship containers |

> **In this module we use ZIP code.** It lets you focus on what a Lambda *is*: handler, event, role and logs. Container images are covered conceptually in [3.13 Containers](../3.13-containers/README.md).

### By invocation type

| Invocation | Who waits for the result? | Retries on error | Examples |
|------------|---------------------------|------------------|----------|
| **Synchronous** | The caller waits for the response | No, the caller decides | API Gateway, Function URL, Console **Test**, `aws lambda invoke` |
| **Asynchronous** | Nobody. The event is queued and Lambda returns at once | **Yes, 2 retries**, then an optional *destination* or dead-letter queue | **S3**, SNS, EventBridge |
| **Event source mapping** (polling) | Lambda **polls** the source and invokes the function with batches | Depends on the source | SQS, Kinesis, DynamoDB Streams |

### By where it runs

| Option | Description |
|--------|-------------|
| **Lambda (standard)** | Runs in an AWS Region on AWS-managed serverless compute. This is what you use in this module |
| **Lambda@Edge** | Runs at CloudFront edge locations, close to users, to change requests and responses (redirects, headers, authentication) |
| **Lambda Managed Instances** | Runs your functions on EC2 instance types that you choose (an *EC2 capacity provider*), for steady, high-volume workloads |

> **Exam tip:** "Run code without provisioning servers, pay only for compute time, up to 15 minutes" → **Lambda**. "Code at CloudFront edge locations" → **Lambda@Edge**.

---

## 4. Cold Starts and Warm Starts

The first time a function runs, or after it has been idle, Lambda must create a new **execution environment**: start a micro-VM, load the runtime, and run your code outside the handler. This is a **cold start**, and it appears in the logs as `Init Duration`.

The environment is then **reused** for following invocations. These are **warm starts**: faster, with no `Init Duration`.

```
REPORT ... Duration: 357.23 ms  Billed Duration: 897 ms ... Init Duration: 539.39 ms   ← cold start
REPORT ... Duration:  79.95 ms  Billed Duration:  80 ms ...                             ← warm start
```

- Since August 2025, the **INIT phase is billed** too: *Billed Duration* = run time + init time on a cold start.
- Put expensive setup, such as creating an SDK client, **outside the handler**, so it runs once per environment and not on every invocation.
- Changing the code or configuration (for example an environment variable) creates **new** environments, which means a cold start again.

### Reserved Concurrency vs. Provisioned Concurrency

It is common to confuse these two controls, but they serve entirely different primary purposes:

| Feature | Primary Purpose | Cost | Cold Start Impact |
|---------|-----------------|------|-------------------|
| **Reserved Concurrency** | Limits the maximum execution environments a function can consume (protects downstream resources or guarantees an account quota pool). | Free | None (still subjects environments to cold starts). |
| **Provisioned Concurrency** | Pre-allocates and warms environments to ensure instant response times. | Paid (incurs a continuous hourly charge) | Eliminates cold starts up to the provisioned limit. |

---

## 5. Pricing

| Item | Price (us-east-1, x86) | Free Tier (every month, no expiry) |
|------|------------------------|-------------------------------------|
| Requests | $0.20 per 1 million | 1 million requests |
| Duration | ~$0.0000167 per **GB-second** | 400,000 GB-seconds |

A **GB-second** is memory (in GB) × run time (in seconds). A 128 MB function running for 100 ms uses 0.125 GB × 0.1 s = **0.0125 GB-seconds**. The free tier covers about 32 million of those invocations per month.

> 💰 The labs in this module are effectively **free**. The functions, a few test invocations and a few small S3 objects stay far inside the Free Tier.

---

## 6. Lambda vs. EC2 vs. Containers

| | **AWS Lambda** | **Amazon EC2** ([3.03](../3.01-ec2/README.md)) | **ECS/Fargate** ([3.06](../3.13-containers/README.md)) |
|---|---|---|---|
| You manage | Code only | OS, patches, scaling, capacity | Container images and task definitions |
| Scaling | Automatic, per request | Auto Scaling Groups ([3.10](../3.08-load-balancing-auto-scaling/README.md)) | Service auto scaling |
| Run time | Up to 15 minutes per invocation | Unlimited | Unlimited |
| Billing | Per request + per ms of run time | Per second while the instance runs, even when idle | Per second for vCPU and memory while tasks run |
| Idle cost | **$0** | Full price | Full price for running tasks |
| Best for | Short, event-driven tasks, spiky traffic | Long-running servers, full OS control, special hardware | Long-running containerized services |

---

## 7. Limits Worth Knowing

| Limit | Value |
|-------|-------|
| Maximum timeout | 15 minutes |
| Memory | 128 MB – 10,240 MB |
| Ephemeral storage (`/tmp`) | 512 MB – 10,240 MB |
| ZIP package size | 50 MB zipped (direct upload), 250 MB unzipped |
| Container image size | 10 GB |
| Synchronous payload | 6 MB request / 6 MB response |
| Concurrent executions | 1,000 per Region by default (a soft limit, can be increased) |

---

## 🧪 LAB 1 (Advanced): Your First Lambda Function

> 💰 **Cost:** effectively **$0**, because everything stays inside the Lambda Free Tier.

**Goal:** Create a Python function in the Console, run it with a test event, read its logs in CloudWatch, and change its behavior with an environment variable, without touching the code.

**Tools:** Console (and optionally the AWS CLI). Region: `us-east-1`. The code is in [`artifacts/hello/lambda_function.py`](artifacts/hello/lambda_function.py):

```python
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
```

### Tasks

**Part A: Create the function**

1. Open **Lambda → Create function → Author from scratch**.
2. Function name: `lab-hello`. Runtime: **Python 3.14**. Architecture: the default.
3. Permissions: keep the default, **Create a new role with basic Lambda permissions**. Lambda creates an execution role that can write to CloudWatch Logs.
4. Choose **Create function**.

**Part B: Deploy the code**

5. In the **Code** tab, open `lambda_function.py`, replace its content with the code above, and choose **Deploy**.

**Part C: Test**

6. Create a test event named `student-test` with this JSON, and choose **Test**:
   ```json
   { "name": "Student" }
   ```
7. Read the **Response** and the **Function Logs** in the output panel. Find `Duration`, `Billed Duration`, `Memory Size`, `Max Memory Used` and `Init Duration`.
8. Choose **Test** again. What changed in the `REPORT` line?

**Part D: Environment variable**

9. Open **Configuration → Environment variables → Edit** and add `GREETING` = `Shalom`. Save.
10. Run the `student-test` event again. What's the response now?
11. Create another test event with an **empty** JSON object, `{}`, and run it. Explain the result.

**Part E: CloudWatch Logs**

12. Open **Monitor → View CloudWatch logs**. Open the newest **log stream** and find your `print()` line and the `REPORT` line.
13. How many log streams are there? Why?

**Part F (optional): Invoke from the CLI**

14. Invoke the function from your terminal with the payload `{"name": "CLI"}` and print the response. **Google it...**

**Part G: Clean up**

15. Delete the function `lab-hello`, its log group `/aws/lambda/lab-hello`, and the execution role that Lambda created for it (`lab-hello-role-xxxxxxxx`).

### Questions

- What do the two parts of the handler name `lambda_function.lambda_handler` mean?
- Why did the first test show `Init Duration` and the second one didn't? Why is *Billed Duration* bigger than *Duration* on the first call?
- What's the advantage of reading `GREETING` from an environment variable instead of writing it in the code?
- The function never asked for permission to write logs. How does it have that permission?

---

## 🧪 LAB 2: S3 Upload → Lambda "Scanner" → Clean Bucket

Lab 2 has its own page: **[LAB2.md](LAB2.md)**

---


## Solutions

- **[Lab 1 Solution](SOLUTION-LAB1.md)**: Console steps, screenshots and CLI commands for the first function
- **[Lab 2 Solution](SOLUTION-LAB2.md)**: the S3 → Lambda → S3 pipeline, Console and CLI

---

[⬅ Previous: 3.05 Monitoring & Auditing](../3.05-monitoring/README.md) | [🏠 Home](../README.md) | [Next: 3.07 Advanced VPC ➡](../3.07-advanced-vpc/README.md)

---

## Terraform Code

> Terraform is covered later in the course. The code is here **for reference**.

The [`terraform/`](terraform/) folder builds **both labs**: `lab-hello` with its role and the `GREETING` variable, plus the full Lab 2 pipeline (two buckets, the scanner role with least privilege, `lab-scanner`, the S3 invoke permission and the bucket notification). It also manages the log groups, so `terraform destroy` removes the logs too.

```bash
cd terraform
terraform init
terraform apply      # 13 resources, prints the bucket names and test commands
terraform destroy
```

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
