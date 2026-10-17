# 3.5 Amazon S3

## Topics

- [What is Amazon S3 – object storage, buckets, objects and keys](#1-what-is-amazon-s3)
- [S3 vs. EBS vs. EFS – when to use which](#2-s3-vs-ebs-vs-efs)
- [Storage classes (overview)](#3-storage-classes-overview)
- [Versioning – keeping every version of an object](#4-versioning)
- [S3 permissions – Block Public Access, IAM policies, bucket policies, ACLs](#5-s3-permissions)
- [Permissions example 1: giving a specific IAM user access to a bucket](#example-1-give-a-specific-iam-user-access-to-a-bucket)
- [Permissions example 2: public read access for a website](#example-2-public-read-access-for-a-website)
- [Lab 1: create a bucket with the CLI and view it in the Console](#lab-1-basic-create-an-s3-bucket-with-the-cli)
- [Lab 2: host a static website on S3](#lab-2-basic-host-a-static-website-on-s3)
- [Terraform: the same resources as code](#-terraform)

---

## 1. What is Amazon S3?

**Amazon Simple Storage Service (S3)** is **object storage**. You store files (objects) in containers (buckets) and access them over HTTP(S) through an API. S3 is not a disk you mount.

| Concept | Description |
|---------|-------------|
| **Bucket** | A container for objects. The name must be **globally unique** across all AWS accounts: 3–63 characters, lowercase letters, numbers, `-` and `.` |
| **Object** | A file plus its metadata. It can be from 0 bytes up to **5 TB** |
| **Key** | The object's full name inside the bucket, for example `images/2026/cat.jpg`. "Folders" in the Console are just **key prefixes** |
| **Region** | A bucket lives in **one Region** that you choose. Data doesn't leave the Region unless you copy it |

Key facts:

- **Durability: 99.999999999% (11 nines).** Objects are stored redundantly across **at least 3 Availability Zones**. One Zone storage classes are the exception.
- **Unlimited storage.** There's no capacity to provision, and you pay for what you store.
- **Pricing:** per GB stored per month, per request (PUT, GET…) and for **data transferred out** to the internet. Data transferred in is free.
- **Common uses:** static websites, backups and archives, data lakes, media files, application assets, logs.

Object URL format:

```
https://<bucket-name>.s3.<region>.amazonaws.com/<key>
e.g. https://my-site-bucket.s3.eu-west-1.amazonaws.com/index.html
```

---

## 2. S3 vs. EBS vs. EFS

| | **Amazon S3** | **Amazon EBS** | **Amazon EFS** |
|---|---|---|---|
| Type | **Object** storage | **Block** storage (a disk) | **File** storage (NFS) |
| Accessed via | HTTP(S) API, from anywhere | Attached to **one EC2 instance** (*) | Mounted by **many** instances at once |
| Scope | Regional (multi-AZ) | **One AZ** | Regional (multi-AZ) |
| Size | Unlimited | You provision the size | Grows and shrinks automatically |
| Typical use | Static files, backups, websites, data lakes | OS boot disk, databases on EC2 | Shared files between servers |

(*) Except EBS Multi-Attach, a special case for io1/io2 volumes.

EBS and EFS are covered in [3.4 Storage](../3.4-storage/README.md).

---

## 3. Storage Classes (Overview)

You choose a storage class **per object**. Colder classes are cheaper to store but cost more to retrieve.

| Storage class | Use case |
|---------------|----------|
| **S3 Standard** | Frequently accessed data (the default) |
| **S3 Intelligent-Tiering** | Unknown or changing access patterns. S3 moves objects between tiers automatically |
| **S3 Standard-IA** | Infrequent access, but it must be available immediately |
| **S3 One Zone-IA** | Infrequent access, re-creatable data. Stored in **one AZ** only |
| **S3 Glacier Instant Retrieval** | Archive data accessed about once a quarter, retrieved in milliseconds |
| **S3 Glacier Flexible Retrieval** | Archives, retrieved in minutes to hours |
| **S3 Glacier Deep Archive** | Long-term archive (7–10 years), retrieved within 12–48 hours. The cheapest class |

**Lifecycle rules** can move objects to a colder class automatically, for example to Glacier after 90 days, or delete them.

---

## 4. Versioning

With **versioning**, S3 keeps **every version** of an object. This protects against accidental overwrites and deletes.

| Bucket state | Behavior |
|--------------|----------|
| **Unversioned** (default) | An upload with the same key **overwrites** the object. A delete removes it **permanently** |
| **Enabled** | Each upload creates a **new version** with its own version ID. A delete adds a **delete marker**, and the older versions remain |
| **Suspended** | New uploads stop getting new versions, but existing versions are kept |

```
upload index.html  →  version A  (current)
upload index.html  →  version B  (current), version A kept
delete index.html  →  delete marker (current), versions B and A kept
                      → delete the delete marker to "undelete" the file
```

- Once enabled, versioning **can't be turned off**. It can only be **suspended**.
- **Every version is billed** as stored data. Combine versioning with lifecycle rules that expire old versions.
- Versioning is required for **S3 Replication**, which copies objects to another bucket or Region.

---

## 5. S3 Permissions

**New buckets and objects are private by default.** Only the account that owns them can access them.

| Mechanism | What it is | When to use |
|-----------|------------|-------------|
| **Block Public Access (BPA)** | A safety switch at the **account** and **bucket** level. When it's on, it **overrides** any policy that would make data public | Keep it **on** unless you deliberately need public data |
| **IAM policy** (identity-based) | Attached to a user, group or role: "this identity can do X on bucket Y" | Access for people and applications **in your account** (see [2.1 IAM](../2.1-iam/README.md)) |
| **Bucket policy** (resource-based) | A JSON policy attached to the **bucket**: "these principals can do X on this bucket". It has a `Principal` element | Cross-account access, public access, rules that apply to everyone |
| **ACLs** | A legacy, per-object permission system | **Disabled by default** on new buckets (*Object Ownership = Bucket owner enforced*). Don't use them |

The usual IAM evaluation rules apply: everything is denied by default, an explicit **Allow** grants access, and an explicit **Deny** always wins. For **public** access, both of these must hold:

1. **Block Public Access is off** for the bucket (and the account), **and**
2. a **bucket policy** allows the action for `"Principal": "*"`.

### Example 1: Give a specific IAM user access to a bucket

A bucket policy that lets the IAM user `alice` list the bucket and read and write objects in it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AliceListBucket",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:user/alice" },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::my-team-bucket"
    },
    {
      "Sid": "AliceReadWriteObjects",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::123456789012:user/alice" },
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::my-team-bucket/*"
    }
  ]
}
```

- `s3:ListBucket` applies to the **bucket** ARN. Object actions apply to `bucket/*`.
- For a user in **the same account**, you can get the same result with an **IAM policy** attached to the user, without a `Principal`. That's what you did in [2.1 IAM, Lab 2](../2.1-iam/README.md). For a user in **another account**, the bucket policy is required.

### Example 2: Public read access, for a website

A bucket policy that lets **anyone on the internet** read (download) objects, but not list, upload or delete them:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-site-bucket/*"
    }
  ]
}
```

- `"Principal": "*"` means **everyone**, including anonymous users.
- This works **only after you turn off Block Public Access** on the bucket. Otherwise S3 rejects the policy.
- ⚠️ Use public buckets only for content that is meant to be public. Many data leaks were caused by buckets that were made public by mistake.

---

## LAB 1 (Basic): Create an S3 Bucket with the CLI

**Goal:** Create a bucket from the command line, enable versioning, and inspect the bucket in the Console.

**Tools:** AWS CLI and Console. Complete [00 Getting Started](../00-getting-started/README.md) first. The examples use `us-east-1`.

### Tasks

**Part A: Create the S3 bucket**

1. Choose a **globally unique** bucket name, for example `s3-lab-<your-name>-<random-number>`.
2. Create the bucket with the **AWS CLI**.
#### Hint:
```bash
aws s3 help
```

3. List your buckets with the CLI and confirm the new bucket appears.
4. Sign in to the **AWS Management Console**, open **S3** and find your bucket. Check:
   - **Objects** tab: the bucket is empty.
   - **Properties** tab: the **Region** and **Bucket Versioning** status.
   - **Permissions** tab: the **Block public access** settings.

**Part B: Versioning**

5. **Enable versioning** on the bucket using the Console or with AWS CLI.

**Part C (HARD!): Limit access to the bucket**

6. Allow access only from your default VPC.
7. Allow access only with TLS 1.2 or higher.
8. Remove the bucket policy (and the VPC endpoint, if you created one) before Lab 2.

### Questions
- What happens if you try to create a bucket with a name that someone else already uses?
- Is the new bucket public or private? How can you tell?
- What happens to an object in this bucket if you upload a file with the same name twice?

---

## LAB 2 (Basic): Host a Static Website on S3

**Goal:** Make the bucket from Lab 1 publicly readable, upload an HTML page and open it in a browser.

**Tools:** Console + AWS CLI. The example page is in this repo: [`artifacts/index.html`](artifacts/index.html).

### Tasks

**Part A: Allow public read access**

1. In the **Console**, open your bucket and go to the **Permissions** tab.
2. Under **Block public access (bucket settings)**, choose **Edit**, clear **Block all public access**, save and confirm.
3. Under **Bucket policy**, choose **Edit** and add the **public read** policy from [Example 2](#example-2-public-read-access-for-a-website). Replace the bucket name with your own.
4. Confirm that the **Permissions** tab now shows **Block all public access: Off** and the new bucket policy.

**Part B: Upload the web page**

5. Upload `artifacts/index.html` to the bucket with the **CLI**.
6. In the Console, refresh the **Objects** tab and confirm that `index.html` is there.

**Part C: Browse to the website**

7. Select `index.html` and copy its **Object URL**.
8. Open the URL in a browser. You should see **"Hello from Amazon S3!"**
9. **Bonus: static website hosting.** On the **Properties** tab, enable **Static website hosting** with `index.html` as the index document. Open the **bucket website endpoint** at the bottom of the Properties tab, then compare the two URLs.

**Part D: Clean up**

10. Delete all objects, including all versions, and then delete the bucket.

### Questions

- Why did the bucket policy need Block Public Access to be turned off?
- Open `https://<bucket>.s3.<region>.amazonaws.com/` (without `index.html`) in the browser. Why do you get *Access Denied*?
- The website endpoint uses `http://`, not `https://`. How would you serve the site over HTTPS? (Hint: Amazon CloudFront.)

---

## 🏗️ Terraform

The [`terraform/`](terraform/) folder builds the full result of both labs as code: the bucket, versioning, public access settings, the bucket policy, static website hosting and the `index.html` upload.

```bash
cd terraform
terraform init
terraform apply      # prints the object URL and the website endpoint
terraform destroy    # clean up
```

---

## ✅ Solutions

Step-by-step solutions:

- **[Lab 1 Solution](SOLUTION-LAB1.md)**: create a bucket, versioning, and limiting access by VPC and TLS
- **[Lab 2 Solution](SOLUTION-LAB2.md)**: static website, cleanup, and Terraform

---

[⬅ Previous: 3.4 Storage: EBS & EFS](../3.4-storage/README.md) | [🏠 Home](../README.md) | [Next: 3.6 Containers: ECR, ECS & Fargate ➡](../3.6-containers/README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)