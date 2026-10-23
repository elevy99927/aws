# 3.06 AWS Lambda – jb-lab-2: Image Upload → Thumbnail

[⬅ jb-lab-1](jb-lab-1.md) | [⬅ Back to 3.06 AWS Lambda](README.md) | [jb-lab-3 ➡](jb-lab-3.md)

> 📚 Based on the course slides *AWS Lambda – Example*: an app for image uploading, where each uploaded image must be resized before it's stored. The upload is the **event source** that triggers the Lambda function.

---

## 🧪 jb-lab-2 (Basic): Image Upload → Thumbnail

**Goal:** Build the slides' example for real. Uploading an image to a **source bucket** triggers a Lambda function that creates a **thumbnail** (max 200×200 px) in a **destination bucket**. Along the way you'll package a function **with a third-party library** (Pillow), which the Lambda runtime doesn't include.

```
                (1) upload                (2) notification          (3) invoke
  👤 user ──────────────────► [ images bucket ] ──────────► S3 ──────────────────► λ jb-lab-2-thumbnailer
                                                                                      │  (4) execution role:
                                                                                      │      read images, write thumbnails
                                                                                      ▼
                                                                    (5) [ thumbnails bucket ]  200×200 px
```

| Step in the slides | In this lab |
|--------------------|-------------|
| 1. The user uploads an image to a source bucket that has a notification | `aws s3 cp sample.jpg s3://<images-bucket>/` |
| 2. S3 reads the notification and decides where to send it | The bucket's **event notification**: `s3:ObjectCreated:*` → Lambda |
| 3. S3 sends the notification to Lambda, which acts as an invoke | An **asynchronous** invocation with an S3 event |
| 4. The execution role (IAM) gives access to AWS resources | `lab-jb2-role`: read from `images`, write to `thumbnails` |
| 5. Lambda runs the function on the uploaded object | Pillow resizes the image, and the function saves it |

**Tools:** Console + AWS CLI + `pip` (Python 3) or AWS CloudShell. Region: `us-east-1`.

**Files:** [`artifacts/jb-lab-2/`](artifacts/jb-lab-2/)

| File | What it is |
|------|------------|
| [`lambda_function.py`](artifacts/jb-lab-2/lambda_function.py) | The handler: read the image, resize it, write the thumbnail |
| [`build.sh`](artifacts/jb-lab-2/build.sh) | Builds `function.zip`: the handler + **Pillow compiled for Lambda** (Linux x86_64, Python 3.14) |
| [`sample.jpg`](artifacts/jb-lab-2/sample.jpg) | A 1600×1000 test image |

> ⚠️ **Never write the thumbnail to the bucket that triggers the function.** Every write would be a new upload, which triggers the function again, in an endless loop. That's why this lab uses **two** buckets.

---

## Tasks

**Part A: Two buckets**

1. Create two buckets with the same suffix: `jblabs-<your-name>-images` and `jblabs-<your-name>-thumbnails`.

**Part B: Execution role**

2. Create an IAM role **`lab-jb2-role`** for **Lambda** with the AWS managed policy `AWSLambdaBasicExecutionRole`.
3. Add an inline policy that allows **only** `s3:GetObject` on the **images** bucket and `s3:PutObject` on the **thumbnails** bucket.

**Part C: Build the deployment package**

4. The code uses **Pillow** (`from PIL import Image`), which isn't part of the Lambda Python runtime. Run `build.sh` to create `function.zip`.
5. List the contents of `function.zip`. What's inside besides `lambda_function.py`? How big is it?

**Part D: The function**

6. Create a function **`jb-lab-2-thumbnailer`**: Python 3.14, **existing role** `lab-jb2-role`.
7. Upload **`function.zip`** (*Upload from → .zip file*). Look at the **Code** tab: what's there besides `lambda_function.py`?
8. Configure:
   - **Memory: 512 MB** and **Timeout: 30 seconds** (image processing needs more than the defaults).
   - Environment variables: `DEST_BUCKET` = your thumbnails bucket, and `MAX_SIZE` = `200`.

**Part E: The trigger**

9. Add an **S3 trigger**: your **images** bucket, **All object create events**.

**Part F: Test**

10. Upload `sample.jpg` to the **images** bucket.
11. A few seconds later, download `sample.jpg` from the **thumbnails** bucket. What size is it, in pixels and in KB?
12. Upload a **text file** to the images bucket. What happens? Check the logs.
13. In **CloudWatch Logs**, find the `processing`, `resized` and `skipping` lines.

**Part G: Clean up**

14. Delete both buckets (with their objects), the function, its log group, and the role `lab-jb2-role`.

---

## Questions

- Which of the five steps in the slides' diagram does **AWS** handle, and which ones do **you** configure?
- Why did you have to build a `.zip` with Pillow inside? What would happen if you uploaded only `lambda_function.py`?
- Why does `build.sh` use `--platform manylinux2014_x86_64` and `--python-version 3.14`, instead of a plain `pip install pillow`?
- The function received a text file and didn't fail. Why is that important for an **asynchronous** event source like S3?
- To do the same thing without Lambda, what would you need to run and manage? (See the slides: "If we were to solve this scenario traditionally…")

---

✅ **Solution:** [jb-lab-2 Solution](jb-lab-2-solution.md)

---

[⬅ jb-lab-1](jb-lab-1.md) | [⬅ Back to 3.06 AWS Lambda](README.md) | [jb-lab-3 ➡](jb-lab-3.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
