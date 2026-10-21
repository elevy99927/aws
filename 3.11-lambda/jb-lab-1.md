# 3.11 AWS Lambda – jb-lab-1: Lambda Runs Functions

[⬅ Back to 3.11 AWS Lambda](README.md) | [jb-lab-2 ➡](jb-lab-2.md)

> 📚 Based on the course slides *AWS Lambda – What it's all about*: "So what is it?", "Lambda runs functions" and "How does it work?" (event source → function).

---

## 🧪 jb-lab-1 (Basic): Lambda Runs Functions

**Goal:** See how a Lambda function works from the inside. A function **runs only when it's invoked**, it receives an **event** (JSON) and a **context**, and it returns a **response**. Everything it prints goes to **CloudWatch Logs**. You'll invoke the same function with different events, make it fail, and invoke it both **synchronously** and **asynchronously**.

**Tools:** Console + AWS CLI. Region: `us-east-1`.

> 🏫 **Classroom account rules:** work only in **`us-east-1`**. Name the function **`jb-lab-1`** and its execution role **`lab-jb1-role`**.

**Code:** [`artifacts/jb-lab-1/lambda_function.py`](artifacts/jb-lab-1/lambda_function.py)

```python
import json


def lambda_handler(event, context):
    # 1. The event: the JSON document that describes "what happened"
    print("event received:", json.dumps(event))

    # 2. The context: information about this invocation
    print(
        f"function={context.function_name} "
        f"memory={context.memory_limit_in_mb}MB "
        f"request_id={context.aws_request_id}"
    )

    # 3. The function's work, driven by the event
    action = event.get("action", "hello")
    if action == "add":
        result = sum(event.get("numbers", []))
    elif action == "upper":
        result = event.get("text", "").upper()
    else:
        result = "Hello from jb-lab-1!"

    print(f"action={action} result={result} remaining_ms={context.get_remaining_time_in_millis()}")

    # 4. The return value is the response to a synchronous caller
    return {"action": action, "result": result}
```

**Test events:** [`artifacts/jb-lab-1/events/`](artifacts/jb-lab-1/events/)

| File | Event |
|------|-------|
| `add.json` | `{ "action": "add", "numbers": [10, 20, 12] }` |
| `upper.json` | `{ "action": "upper", "text": "aws lambda runs functions" }` |
| `empty.json` | `{}` |
| `bad-add.json` | `{ "action": "add", "numbers": [1, "two", 3] }` |

---

## Tasks

**Part A: Create the function**

1. In **IAM → Roles → Create role**, choose **AWS service → Lambda**, attach the AWS managed policy **`AWSLambdaBasicExecutionRole`**, and name the role **`lab-jb1-role`**.
2. In **Lambda → Create function → Author from scratch**, create a function named **`jb-lab-1`** with runtime **Python 3.14**. Under *Change default execution role*, choose **Use an existing role → `lab-jb1-role`**.
3. Replace the code in `lambda_function.py` with the lab code, and choose **Deploy**.

**Part B: One function, many events**

4. Create three test events, `add`, `upper` and `empty`, from the files above, and run each one.
5. For each one, write down the **response** and find the `event received:` line in the **Function Logs**.

**Part C: When the function fails**

6. Create a test event `bad-add` from `bad-add.json` and run it.
7. What's the **status** of the invocation? What do the response and the logs contain?

**Part D: Synchronous vs. asynchronous invocation**

8. Invoke the function from the CLI **synchronously** with `add.json`, and print the response.
9. Invoke it **asynchronously** (`--invocation-type Event`) with `upper.json`. What does the CLI return? Where can you see the result?

**Part E: Logs**

10. Open **Monitor → View CloudWatch logs**. Find the log lines of every invocation from Parts B–D, including the asynchronous one and the failed one.

**Part F: Clean up**

11. Delete the function `jb-lab-1`, its log group `/aws/lambda/jb-lab-1`, and its execution role.

---

## Questions

- What is an **event source**? Which event sources did you use in this lab?
- What's the difference between the **event** and the **context**?
- The function failed in Part C, but Lambda itself didn't. How can you tell the difference?
- Why didn't the asynchronous invocation return the function's result?
- In the slides, "a lambda function is a small anonymous function". How is an **AWS Lambda function** different from a `lambda` in Python?

---

✅ **Solution:** [jb-lab-1 Solution](jb-lab-1-solution.md)

---

[⬅ Back to 3.11 AWS Lambda](README.md) | [jb-lab-2 ➡](jb-lab-2.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
