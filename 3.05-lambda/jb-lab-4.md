# 3.05 AWS Lambda – Lab 4: An S3 Upload Triggers a Node.js Function

[⬅ Lab 3](jb-lab-3.md) | [⬅ Back to 3.05 AWS Lambda](README.md) | [Walkthrough ➡](jb-lab-4-walkthrough.md)

**▶ Video walkthrough** (9 min):

[![Video: Lambda – An S3 upload triggers a Node.js function](https://img.youtube.com/vi/q6A6g63uLgQ/maxresdefault.jpg)](https://youtu.be/q6A6g63uLgQ)

> 📚 Based on the course hands-on *AWS Lambda DIY*. Updated for your own AWS account: you create your own bucket instead of using a shared class bucket, with Node.js 24.x and today's Console.

---

## 🧪 lab-4 (Basic): An S3 Upload Triggers a Node.js Function

**Goal:** Create a Lambda function in **Node.js** that writes **"An object was added"** to its log every time a file is uploaded to your S3 bucket. You upload the file with the **AWS CLI**, and find the log line in **CloudWatch Logs**. In the home lab, only `.jpg` files trigger the function, and it logs the file's name.

![Lab 4: you upload a file with the AWS CLI to your S3 bucket; the S3 event invokes lab-4-object-logger (Node.js 24.x) asynchronously; console.log writes "An object was added" to CloudWatch Logs. The S3 trigger adds a resource-based policy that lets S3 invoke the function. The execution role only writes logs. In Part F, a .jpg suffix filter means only .jpg uploads invoke the function.](images/jb4-s3-trigger.jpg)

<sub>Diagram source: [images/jb4-s3-trigger.drawio](images/jb4-s3-trigger.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

**Tools:** Console + AWS CLI. [AWS CloudShell](https://console.aws.amazon.com/cloudshell/) works well: the CLI is already installed and signed in. Region: `us-east-1`.

**Code:** [`artifacts/jb-lab-4/index.mjs`](artifacts/jb-lab-4/index.mjs)

```js
// Runs every time S3 sends an "object created" event
export const handler = async (event) => {
  console.log('An object was added');
};
```

> 💰 **Cost:** expected to be a few cents at most: a few Lambda invocations, small S3 objects and a few log lines. Whether the Free Tier covers it depends on your account's plan, credits and other usage. Delete everything at the end.

---

## Tasks

**Part A: The bucket**

1. Create an S3 bucket **`labs-<your-name>-lab4-uploads`** in `us-east-1`. Bucket names are global: if the name is taken, add a few digits.

**Part B: The function**

2. Create a function **`lab-4-object-logger`**: *Author from scratch*, runtime **Node.js 24.x**. Keep the default execution role (*Create a new role with basic Lambda permissions*).
3. Which permissions does the new execution role have?

**Part C: The S3 trigger**

4. Add a trigger: **S3**, your bucket, event types **All object create events**. Read the warning about recursive invocation, and acknowledge it.
5. Look at the function's **resource-based policy**. What did the trigger add?

**Part D: The code**

6. Replace the code in **`index.mjs`** with the lab code, and **Deploy**.

**Part E: Test**

7. With the AWS CLI, upload a file to your bucket.
8. Run `aws s3 ls` on the bucket to check that the file is there.
9. Open the function's logs in **CloudWatch Logs**, and find **"An object was added"**.

**Part F: Home lab**

10. Make only **`.jpg`** files trigger the function.
11. Make the function write the **name of the file** to the log. The event that S3 sends contains it.
12. Upload `notes.txt` and `photo.jpg`. Which of them appear in the log? Is `notes.txt` in the bucket?
13. *(Going further)* Make the bucket **reject** every upload that isn't a `.jpg`. Hint: a bucket policy with an explicit `Deny`.

**Part G: Clean up**

14. Delete the function, its execution role and its log group. Empty the bucket, and delete it.

---

## Questions

1. Who invokes the function, and how does Lambda know that S3 is allowed to?
2. Why does the execution role need no S3 permissions in this lab?
3. Does the upload wait for the function to finish? Why?
4. In Part F, why doesn't `notes.txt` appear in the log? Was it uploaded?

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
