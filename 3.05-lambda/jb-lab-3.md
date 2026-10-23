# 3.05 AWS Lambda – Lab 3: Limits and Pricing

[⬅ Lab 2](jb-lab-2.md) | [⬅ Back to 3.05 AWS Lambda](README.md)

> 📚 Based on the course slides *Limitations of AWS Lambda* and *Pricing in AWS Lambda*. The slides are from 2020, and some of their numbers have changed since. In this lab you **measure** the current behavior yourself.

---

## 🧪 lab-3 (Basic): Limits and Pricing

**Goal:** Measure how **memory** affects **speed** and **cost**, hit the **timeout** limit on purpose, and calculate what a function costs per month.

**Tools:** Console + AWS CLI. Region: `us-east-1`.

**Code:** [`artifacts/jb-lab-3/lambda_function.py`](artifacts/jb-lab-3/lambda_function.py). It does CPU work (repeated SHA-256 hashing) and can also **wait** without using CPU, like a slow API call:

```python
import hashlib
import time


def lambda_handler(event, context):
    rounds = int(event.get("rounds", 100000))   # CPU work: repeated SHA-256 hashing
    sleep_s = float(event.get("sleep", 0))      # waiting (no CPU), e.g. a slow API call

    start = time.time()
    digest = b"lab-3"
    for _ in range(rounds):
        digest = hashlib.sha256(digest).digest()
    time.sleep(sleep_s)
    took_ms = round((time.time() - start) * 1000)

    print(f"rounds={rounds} sleep={sleep_s}s took_ms={took_ms} memory={context.memory_limit_in_mb}MB")
    return {"rounds": rounds, "sleep": sleep_s, "took_ms": took_ms, "memory_mb": int(context.memory_limit_in_mb)}
```

**Test events:** 
Create 2 tests Events:
- CPU: [`events/cpu.json`](artifacts/jb-lab-3/events/cpu.json) = `{ "rounds": 100000 }`
- SLOW  [`events/slow.json`](artifacts/jb-lab-3/events/slow.json) = `{ "rounds": 0, "sleep": 5 }`

### Reminder: how Lambda is priced

| Charge | Price (us-east-1, x86) | Free Tier (every month) |
|--------|------------------------|-------------------------|
| Requests | $0.20 per 1 million | 1 million requests |
| Duration | $0.0000166667 per **GB-second**, billed **per 1 ms** | 400,000 GB-seconds |

**GB-seconds** = memory in GB × billed duration in seconds. For example, 512 MB for 200 ms is 0.5 × 0.2 = **0.1 GB-s**.

---

## Tasks

**Part A: Create the function**

1. Create an execution role **`lab-3-role`** for Lambda with `AWSLambdaBasicExecutionRole`, as in [Lab 1](jb-lab-1.md).
2. Create a function **`lab-3-benchmark`** with Python 3.14, the existing role `lab-3-role`, and the lab code. Keep the defaults: **128 MB** memory and a **3-second** timeout.

**Part B: Measure at 128 MB**

3. Run `cpu.json` **twice**. Use the **second** run (a warm start). From the `REPORT` line, write down `Duration`, `Billed Duration` and `Memory Size`.
4. Calculate the **GB-seconds** and the **cost** of one invocation.

**Part C: Measure at 1024 MB**

5. Change the memory to **1024 MB** and run `cpu.json` twice again. Write down the numbers from the second run.
6. Compare with Part B. How much faster was it? How did the **cost per invocation** change?

**Part D: Hit the timeout**

7. Run `slow.json`, which waits 5 seconds, with the default **3-second** timeout. What happens?
8. Increase the timeout to **10 seconds** and run it again.
9. Compare `Billed Duration` with the `took_ms` in the response. What are you paying for while the function only waits?

**Part E: Monthly cost**

10. A function runs **3 million times a month**, for **200 ms** each, with **512 MB** of memory. Calculate the monthly cost **with** and **without** the Free Tier.

**Part F: Clean up**

11. Delete the function `lab-3-benchmark`, its log group `/aws/lambda/lab-3-benchmark`, and its execution role.

---

## Questions

- Why did the function run faster with more memory, even though it hardly uses any memory?
- Is more memory always more expensive? When can it be cheaper?
- What happens to a function that runs past its timeout? Is the time until the timeout billed?
- The slides say: "the execution timeout can be maximized to just 5 minutes", "memory between 128 MB and 1536 MB", "rounded up to the nearest 100 ms". What are the current values?
- Which workloads from the slides would you **not** run on Lambda because of these limits?

---

✅ **Solution:** [Lab 3 Solution](jb-lab-3-solution.md)

---

[⬅ Lab 2](jb-lab-2.md) | [⬅ Back to 3.05 AWS Lambda](README.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
