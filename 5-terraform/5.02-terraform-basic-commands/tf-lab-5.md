# 5.02 Terraform Basic Commands – Lab 5: Remote State in S3, with a DynamoDB Lock

[⬅ Lab 4](tf-lab-4.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-5-solution/README.md) | [Lab 6 ➡](tf-lab-6.md)

[![Video: Terraform – Remote state in S3, with a DynamoDB lock](https://img.youtube.com/vi/BsQvI3YA7bs/maxresdefault.jpg)](https://youtu.be/BsQvI3YA7bs)

Until now, the state file, `terraform.tfstate`, lived in your folder. Lose the folder, and Terraform forgets everything it built; work from a second computer, and it doesn't know the resources exist; run two applies at once, and the state can end up corrupted. In this lab you move the state to an S3 bucket, and add a **lock** in a DynamoDB table, so only one command works on the state at a time. Then you watch the lock: a second command is refused while an apply is waiting, and you learn what to do with a lock left behind.

## Remote state and the lock

| | What it is | Where |
|---|---|---|
| **Remote state** (`backend "s3"`) | The state file is stored in an S3 bucket instead of your folder | S3 |
| **State lock** (`dynamodb_table`) | Before every `plan`, `apply` and `destroy`, Terraform writes a lock item in a DynamoDB table, and deletes it when the command ends. A second command is refused while the item exists | DynamoDB |

> Since Terraform 1.10 the S3 backend can also lock the state by itself (`use_lockfile = true`, a lock file next to the state). `dynamodb_table` still works and prints a deprecation warning; many teams still run the table, so this lab shows it.

## What you add

| What | Settings |
|---|---|
| State bucket | `tfstate-<yourname>-<random number>`, for example `tfstate-dana-4821`, with versioning, created with the AWS CLI |
| Lock table | `tfstate-lock`: a DynamoDB table with one string key, `LockID`, pay per request, created with the AWS CLI |
| Backend | `backend "s3"`: the bucket, the key `tf-lab-5/terraform.tfstate`, `us-east-1`, `dynamodb_table = "tfstate-lock"` |

Region: **`us-east-1`**.

Before you start:
- [Lab 4](tf-lab-4.md): this lab continues from its folder, `tf-lab-4`, with its SSH key and its `TF_VAR_MY_IP`.
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)). The S3 backend uses the AWS CLI's sign-in (or the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables), not the provider's `TF_VAR_` variables.

> 💰 **Cost:** the Lab 4 instances and their public IPv4 addresses for the length of the lab cost a few cents. The state bucket holds a few kilobytes and the lock table is pay per request: both cost nothing noticeable; keep them for the next labs.

## Steps

### Part 1: Remote state in S3

1. **Copy the Lab 4 folder** to a new folder, and work there:
   ```bash
   cp -r tf-lab-4 tf-lab-5
   cd tf-lab-5
   ```
   - Set your IP address again if this is a new terminal: `export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"`.
   - If you destroyed the Lab 4 resources, run `terraform apply` once now, so there is a state to move.
2. **Create the state bucket** with the AWS CLI, with your own name and a random number:
   ```bash
   aws s3api create-bucket --bucket tfstate-<yourname>-<number> --region us-east-1
   aws s3api put-bucket-versioning --bucket tfstate-<yourname>-<number> --versioning-configuration Status=Enabled
   aws s3api get-bucket-versioning --bucket tfstate-<yourname>-<number>
   ```
   - Terraform can't create the bucket that stores its own state: the bucket must exist before `terraform init`.
   - Versioning keeps every earlier version of the state, so an earlier state file can be restored if something goes wrong. The last command checks it: `"Status": "Enabled"`.
3. **Create the lock table:**
   ```bash
   aws dynamodb create-table \
     --table-name tfstate-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```
   - The key must be a string named `LockID`: that's the name Terraform looks for.
   - Pay per request: the table costs nothing while it's idle.
4. **The backend.** In a new file, `backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "tfstate-<yourname>-<number>"
       key            = "tf-lab-5/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "tfstate-lock"
     }
   }
   ```
   - A backend block can't use variables: write the values in.
5. **Move the state:** run `terraform init -migrate-state`, and answer `yes` when Terraform asks to copy the existing state to the new backend.
6. **Check:**
   - `terraform plan` says **No changes**: Terraform reads the same state, now from S3.
   - In the AWS Console, **S3 → your state bucket → `tf-lab-5/`**: the object `terraform.tfstate`.
   - Your local `terraform.tfstate` is now empty, and `terraform.tfstate.backup` holds the old copy: once `plan` says No changes, you can delete both.

### Part 2: The lock

7. **An apply that waits.** In `instance.tf`, change the `Name` tag of `web_1` to `my-tf-web-1-locked` (a change Terraform makes in place). Run `terraform apply`: it shows `1 to change` and waits at `Enter a value`. **Don't answer yet.** This terminal holds the lock.
8. **The lock item.** In a second terminal:
   ```bash
   aws dynamodb scan --table-name tfstate-lock
   ```
   - One item has the `LockID` of your state (`<bucket>/tf-lab-5/terraform.tfstate`) and an `Info` with who holds the lock, from which computer, since when, and the operation.
   - A second item ends with `-md5`: a checksum of the state, not a lock. Terraform keeps it to check that the state in S3 is the one it wrote last.
9. **A second command is refused.** Still in the second terminal, run `terraform plan`: `Error: Error acquiring the state lock`, with the lock's ID, who holds it and since when.
10. **Release it:** back in the first terminal, type `yes`. The tag changes, and the lock item is deleted. Scan the table again: only the `-md5` item is left.
11. **A lock left behind.** If a run crashes, or you press Ctrl+C during an apply, the lock item can stay, and every command fails with the same error. `terraform force-unlock <ID>` (the ID from the error message) removes it. Use it only when you're sure nobody is running Terraform on this state.
12. **Clean up:** run `terraform destroy`, and type `yes`.
    - Keep the state bucket and the lock table for the next labs; the bucket holds an empty state, and the table only the `-md5` item.

## Questions

1. Why can't Terraform create the bucket and the table that hold its own state and lock, in the same configuration?
2. After `terraform init -migrate-state`, why does `terraform plan` show no changes?
3. What's in the lock item, and when does Terraform delete it?
4. A teammate runs `terraform apply` while yours is waiting at `Enter a value`. What do they see, and why is that good?
5. When is `terraform force-unlock` safe, and when is it dangerous?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-5-solution/README.md)**, then continue to **[Lab 6](tf-lab-6.md)**: user data and remote-exec.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
