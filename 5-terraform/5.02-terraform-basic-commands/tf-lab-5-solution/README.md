# 5.02 Terraform Basic Commands – Lab 5 Solution

[⬅ Lab 5](../tf-lab-5.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the Lab 4 folder plus one new file:

| File | What it holds |
|---|---|
| [`backend.tf`](backend.tf) **new** | The S3 backend: the state bucket, the key `tf-lab-5/terraform.tfstate`, `us-east-1`, and `dynamodb_table = "tfstate-lock"` |
| [`instance.tf`](instance.tf) | Lab 4's instances; the `Name` tag of `web_1` is `my-tf-web-1-locked` after step 7 |
| [`vars.tf`](vars.tf), [`provider.tf`](provider.tf), [`vpc.tf`](vpc.tf), [`security.tf`](security.tf), [`key.tf`](key.tf), [`s3.tf`](s3.tf), [`outputs.tf`](outputs.tf) | The same as in Lab 4 |

Replace `tfstate-yourname-1234` in `backend.tf` with your own bucket name, and `s3-lab-yourname-1234` in `s3.tf` with your Lab 3 name. Your SSH key files, `my-ssh-key` and `my-ssh-key.pub`, come from your Lab 4 folder.

The terminal blocks below are from the real run, starting from a folder with the 12 Lab 4 resources and a local state. IDs, IP addresses and the user name are masked.

## Part 1: remote state in S3

**The state bucket**, created with the AWS CLI, with versioning:

```text
$ aws s3api create-bucket --bucket tfstate-student-2821 --region us-east-1
{
    "Location": "/tfstate-student-2821",
    "BucketArn": "arn:aws:s3:::tfstate-student-2821"
}
$ aws s3api put-bucket-versioning --bucket tfstate-student-2821 --versioning-configuration Status=Enabled
$ aws s3api get-bucket-versioning --bucket tfstate-student-2821
{
    "Status": "Enabled"
}
```

**The lock table:**

```text
$ aws dynamodb create-table \
    --table-name tfstate-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
{
    "TableDescription": {
        ...
        "TableName": "tfstate-lock",
        "KeySchema": [
            {
                "AttributeName": "LockID",
                "KeyType": "HASH"
            }
        ],
        "TableStatus": "CREATING",
        ...
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST"
        },
        ...
    }
}
```

- Terraform can't create the bucket or the table in the same configuration: `terraform init` needs them before Terraform reads any resource, and `terraform destroy` would try to delete the bucket that holds the state it's using.
- The key must be a string named `LockID`: that's the name Terraform writes.
- A backend block can't use variables (`var.…`): Terraform reads it before variables exist.

**The migration:**

```text
$ terraform init -migrate-state
...
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
...
Terraform has been successfully initialized!
```

```text
$ terraform plan

Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
Acquiring state lock. This may take a few moments...
...
No changes. Your infrastructure matches the configuration.

$ aws s3 ls s3://tfstate-student-2821/ --recursive
2026-11-03 21:07:21      27911 tf-lab-5/terraform.tfstate

$ wc -c terraform.tfstate*
       0 terraform.tfstate
   27911 terraform.tfstate.backup
```

- **No changes:** Terraform read the same 12 resources, now from S3.
- The local `terraform.tfstate` is now **empty** (0 bytes), and `terraform.tfstate.backup` holds the old copy. Once `plan` says No changes, and the object is in the bucket, you can delete both.
- **The warning** appears on every command: since Terraform 1.10 the S3 backend can lock the state itself (`use_lockfile = true`), and `dynamodb_table` is marked deprecated. It still works, and many teams still run the table.
- **Sign-in:** the S3 backend uses the AWS CLI's sign-in (`aws login`) or the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` environment variables. It doesn't read the provider's `TF_VAR_AWS_ACCESS_KEY`.

In the S3 Console, **tfstate-student-2821 → tf-lab-5/** shows one object, `terraform.tfstate`, 27.3 KB. **Show versions** lists every version written since.

## Part 2: the lock

**An apply that waits** (terminal 1), after changing the `Name` tag of `web_1` to `my-tf-web-1-locked`:

```text
$ terraform apply
...
Terraform will perform the following actions:

  # aws_instance.web_1 will be updated in-place
  ~ resource "aws_instance" "web_1" {
        id                                   = "i-0a1b2c3d4e5f60010"
      ~ tags                                 = {
          ~ "Name" = "my-tf-web-1" -> "my-tf-web-1-locked"
        }
        # (39 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

**The lock item** (terminal 2), while the apply waits:

```text
$ aws dynamodb scan --table-name tfstate-lock
{
    "Items": [
        {
            "Digest": {
                "S": "c048fc84b98826620245b53ba6d21f63"
            },
            "LockID": {
                "S": "tfstate-student-2821/tf-lab-5/terraform.tfstate-md5"
            }
        },
        {
            "LockID": {
                "S": "tfstate-student-2821/tf-lab-5/terraform.tfstate"
            },
            "Info": {
                "S": "{\"ID\":\"241005cd-c003-94f0-3dc8-c73d91c01cc9\",\"Operation\":\"OperationTypeApply\",\"Info\":\"\",\"Who\":\"student@laptop\",\"Version\":\"1.15.7\",\"Created\":\"2026-11-03T19:07:35.850859Z\",\"Path\":\"tfstate-student-2821/tf-lab-5/terraform.tfstate\"}"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```

- The lock item's `LockID` is `<bucket>/<key>`. Its `Info` holds the lock's own `ID` (the one `force-unlock` takes), the operation, who holds it (`user@computer`), the Terraform version and the time.
- The `-md5` item is a checksum of the state, not a lock: Terraform compares it with the state it reads from S3, so it never works from a stale copy. It stays in the table after the lock is released.

**A second command is refused** (terminal 2):

```text
$ terraform plan
...
Acquiring state lock. This may take a few moments...

Error: Error acquiring the state lock

Error message: operation error DynamoDB: PutItem, https response error
StatusCode: 400, RequestID: ...,
ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        241005cd-c003-94f0-3dc8-c73d91c01cc9
  Path:      tfstate-student-2821/tf-lab-5/terraform.tfstate
  Operation: OperationTypeApply
  Who:       student@laptop
  Version:   1.15.7
  Created:   2026-11-03 19:07:35.850859 +0000 UTC
  Info:

Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

Terraform writes the lock item with a condition "only if no item with this key exists". DynamoDB refuses (`ConditionalCheckFailedException`), and Terraform stops before reading the state.

**Release:** `yes` in terminal 1.

```text
aws_instance.web_1: Modifying... [id=i-0a1b2c3d4e5f60010]
aws_instance.web_1: Modifications complete after 3s [id=i-0a1b2c3d4e5f60010]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

$ aws dynamodb scan --table-name tfstate-lock --query "Items[].LockID.S"
[
    "tfstate-student-2821/tf-lab-5/terraform.tfstate-md5"
]
```

**A lock left behind:** if a run crashes or you press Ctrl+C during an apply, the item can stay, and every command fails with the error above. `terraform force-unlock 241005cd-c003-94f0-3dc8-c73d91c01cc9` (the `ID` from the error) deletes it, after asking for `yes`. Only when nobody is running Terraform on this state.

## Clean up

```text
$ terraform destroy
...
Plan: 0 to add, 0 to change, 12 to destroy.
...
  Enter a value: yes
...
Destroy complete! Resources: 12 destroyed.

$ aws s3 ls s3://tfstate-student-2821/ --recursive
2026-11-03 21:12:39        181 tf-lab-5/terraform.tfstate
```

The state in S3 is now an empty state (181 bytes), versioning keeps the earlier versions, and the table holds only the `-md5` item. Keep both for the next labs. To delete the bucket later, delete every object version first (the Console's **Empty** button does this), then the bucket; the table goes with `aws dynamodb delete-table --table-name tfstate-lock`.

## Answers

1. **The bucket and the table** must exist before `terraform init`, because the backend is configured before Terraform reads any resource. And if the same configuration managed them, `terraform destroy` would try to delete the bucket that stores the state it's using, and the table that holds its lock.
2. **No changes** after the migration, because the state moved, not the resources: Terraform reads the same 12 resources from S3, and they still match the files.
3. **The lock item** is one DynamoDB item whose `LockID` is `<bucket>/<key>`. Its `Info` says who holds the lock (`user@computer`), since when, which operation (`OperationTypeApply`), the Terraform version, and the lock's own `ID`. Terraform deletes it when the command ends, including when the command fails.
4. **The teammate sees** `Error: Error acquiring the state lock`, with the lock's `ID`, `Who` and `Created`, and their command stops before it reads the state. That's good: two applies writing the same state at once could leave it corrupted or half-applied; now the second one waits for the first to finish, and then plans against the updated state.
5. **`force-unlock` is safe** when the item is left behind by a run that no longer exists (a crash, Ctrl+C, a lost connection): check `Who` and `Created`, and ask the teammate. **It's dangerous** while that run is still working: it removes the only thing that stops a second apply from writing the state at the same time.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
