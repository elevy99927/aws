# 5.02 Terraform Basic Commands – Lab 5 Solution

[⬅ Lab 5](../tf-lab-5.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the Lab 4 folder plus two new files and three changed ones:

| File | What it holds |
|---|---|
| [`backend.tf`](backend.tf) **new** | The S3 backend: the state bucket, the key `tf-lab-5/terraform.tfstate`, `us-east-1`, `use_lockfile = true` |
| [`install-nginx.sh`](install-nginx.sh) **new** | The user-data script: installs nginx and writes a page with the instance's host name |
| [`security.tf`](security.tf) | Lab 4's SSH rule, plus `aws_vpc_security_group_ingress_rule.http`: port 80 from `var.MY_IP` |
| [`instance.tf`](instance.tf) | Both instances get `user_data`, `user_data_replace_on_change = true`, a `connection` block and a `remote-exec` provisioner |
| [`outputs.tf`](outputs.tf) | Lab 4's IP outputs, plus `web_1_url` and `web_2_url` |
| [`vars.tf`](vars.tf), [`provider.tf`](provider.tf), [`vpc.tf`](vpc.tf), [`key.tf`](key.tf), [`s3.tf`](s3.tf) | The same as in Lab 4 |

Replace `tfstate-yourname-1234` in `backend.tf` with your own bucket name, and `s3-lab-yourname-1234` in `s3.tf` with your Lab 3 name. Your SSH key files, `my-ssh-key` and `my-ssh-key.pub`, come from your Lab 4 folder.

## Part 1: remote state in S3

The real run, starting from a folder with the 12 Lab 4 resources and a local state. IDs and IP addresses are masked.

**The state bucket**, created with the AWS CLI, with versioning:

```text
$ aws s3api create-bucket --bucket tfstate-student-2821 --region us-east-1
{
    "Location": "/tfstate-student-2821",
    ...
}
$ aws s3api put-bucket-versioning --bucket tfstate-student-2821 --versioning-configuration Status=Enabled
$ aws s3api get-bucket-versioning --bucket tfstate-student-2821
{
    "Status": "Enabled"
}
```

- Terraform can't create this bucket in the same configuration: `terraform init` needs the bucket to exist before Terraform reads any resource, and `terraform destroy` would try to delete the bucket that holds the state it's using.
- A backend block can't use variables (`var.…`): Terraform reads it before variables exist.

**The migration:**

```text
$ terraform init -migrate-state
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

```text
$ terraform plan
No changes. Your infrastructure matches the configuration.

$ aws s3 ls s3://tfstate-student-2821/ --recursive
2026-11-01 10:00:13      27090 tf-lab-5/terraform.tfstate
```

- **No changes:** Terraform read the same 12 resources, now from S3.
- The local `terraform.tfstate` is now **empty** (0 bytes), and `terraform.tfstate.backup` holds the old copy. Once `plan` says No changes, you can delete both.
- **Sign-in:** the S3 backend uses the AWS CLI's sign-in (`aws login` worked in this run) or the `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` environment variables. It doesn't read the provider's `TF_VAR_AWS_ACCESS_KEY`.

**The lock:** while `terraform apply` ran, a second terminal saw the lock file next to the state:

```text
$ aws s3 ls s3://tfstate-student-2821/ --recursive
2026-11-01 10:00:13      27090 tf-lab-5/terraform.tfstate
2026-11-01 10:01:56        266 tf-lab-5/terraform.tfstate.tflock
```

A second `apply` at that moment would stop with a lock error instead of changing the state at the same time. The lock file is deleted when the command ends.

## Part 2: user data and remote-exec

```hcl
resource "aws_instance" "web_1" {
  # ... as in Lab 4 ...
  user_data                   = file("install-nginx.sh")
  user_data_replace_on_change = true

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("my-ssh-key")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "systemctl is-active nginx",
      "curl -s localhost",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}
```

- `cloud-init status --wait` blocks until cloud-init has run the user-data script, so the next two commands check a finished install.
- Provisioners run in the order they're written: `remote-exec` first, then `local-exec`.

**The plan:**

```text
  # aws_instance.web_1 must be replaced
      + user_data                            = <<-EOT # forces replacement
      ~ user_data_replace_on_change          = false -> true
  # aws_instance.web_2 must be replaced
  ...
  # aws_vpc_security_group_ingress_rule.http will be created

Plan: 3 to add, 0 to change, 2 to destroy.
```

User data runs only at the first boot. Without `user_data_replace_on_change`, Terraform would update the user data on the existing instance (AWS stops and starts it), but cloud-init wouldn't run the script again; with it, Terraform replaces the instance, and the new one runs the script.

**When remote-exec fails.** In this run, the first apply failed:

```text
aws_instance.web_1: Provisioning with 'remote-exec'...
aws_instance.web_1 (remote-exec): Connecting to remote host via SSH...
...
Error: remote-exec provisioner error
timeout - last error: dial tcp 203.0.113.16:22: i/o timeout
```

The computer's public IP address wasn't the one in `TF_VAR_MY_IP` (some networks use more than one), so the security group dropped the SSH connection. Terraform marks an instance whose provisioner failed as **tainted**, and the next plan replaces it:

```text
  # aws_instance.web_1 is tainted, so must be replaced
  # aws_instance.web_2 is tainted, so must be replaced

Plan: 2 to add, 0 to change, 2 to destroy.
```

The network had a second public IP address, and SSH used it. After allowing that address too (a temporary inbound rule, added outside Terraform and removed before `terraform destroy`), the next apply worked, with no change to the Terraform rules (`0 changed`):

```text
aws_instance.web_1 (remote-exec): Connected!
aws_instance.web_1 (remote-exec): status: done
aws_instance.web_1 (remote-exec): active
aws_instance.web_1 (remote-exec): <h1>Hello from ip-10-0-1-194.ec2.internal</h1><p>Installed by user-data</p>
...
Apply complete! Resources: 2 added, 0 changed, 2 destroyed.

Outputs:

web_1_url = "http://203.0.113.11"
web_2_url = "http://203.0.113.12"
```

```text
$ curl http://203.0.113.11
<h1>Hello from ip-10-0-1-194.ec2.internal</h1><p>Installed by user-data</p>
```

## Clean up

```text
$ terraform destroy
Plan: 0 to add, 0 to change, 13 to destroy.
Destroy complete! Resources: 13 destroyed.

$ aws s3 ls s3://tfstate-student-2821/ --recursive
2026-11-01 10:12:31        181 tf-lab-5/terraform.tfstate
```

The state in S3 is now an empty state (181 bytes), and versioning keeps the earlier versions. Keep the bucket for the next labs. To delete it later, delete every object version first (the Console's **Empty** button does this), then the bucket.

## Answers

1. **The state bucket** must exist before `terraform init`, because the backend is configured before Terraform reads any resource. And if the same configuration managed the bucket, `terraform destroy` would try to delete the bucket that stores the state it's using.
2. **No changes** after the migration, because the state moved, not the resources: Terraform reads the same 12 resources from S3, and they still match the files.
3. **One changed line** in `install-nginx.sh` changes `user_data`, which forces a replacement of both instances (because of `user_data_replace_on_change = true`). Without that setting, Terraform would update the user data on the existing instances (AWS stops and starts them), but the new script wouldn't run, since cloud-init runs user data only at the first boot.
4. **Terraform waits for `remote-exec`**, and a failing command (or no SSH connection) fails the apply and taints the instance. **User data** runs inside the instance through cloud-init; Terraform doesn't wait for it and never sees its output, so a broken script doesn't fail the apply. This lab uses `remote-exec` to wait for user data and check its result.
5. **A second person** needs the same files (from Git), the same `backend.tf`, AWS credentials with access to the state bucket, and `terraform init`. Terraform then reads the shared state from S3, and the lock file stops two applies from running at the same time.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
