# 5.02 Terraform Basic Commands – Lab 2 Solution

[⬅ Lab 2](../tf-lab-2.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the three files in this folder:

| File | What it holds |
|---|---|
| [`vars.tf`](vars.tf) | The credential variables (`null` by default), `AWS_REGION` (`us-east-1`) and the `AMIS` map: an Amazon Linux 2023 AMI per Region |
| [`provider.tf`](provider.tf) | The AWS provider (`hashicorp/aws`, version 6), with its keys and Region from the variables |
| [`instance.tf`](instance.tf) | The `aws_instance` called `example`, a `t2.micro` with the tag `Name = "tf-example"` |

## Two ways to sign in

- **`aws login`:** set nothing. The credential variables stay `null`, which the provider treats as "not set", so it uses your AWS CLI session.
- **Access keys:** set them in the shell, and the provider uses them instead:

  ```bash
  export TF_VAR_AWS_ACCESS_KEY=AKIA...
  export TF_VAR_AWS_SECRET_KEY=...
  ```

  Terraform reads every shell variable named `TF_VAR_<name>` as the value of the variable `<name>`. `sensitive = true` hides the values in the output of `plan` and `apply`.

## Steps 3–8: init, plan, apply

```bash
terraform init
terraform plan        # Plan: 1 to add, 0 to change, 0 to destroy.
terraform apply       # type yes
```

- **Why a provider:** Terraform itself doesn't know how to create resources on AWS. The AWS provider holds that logic, and makes the AWS API calls that create, read, update and delete each resource, just as the Google provider does for Google Cloud.
- `terraform init` downloads the AWS provider from the Terraform Registry into `.terraform/`, and writes `.terraform.lock.hcl`, the dependency lock file. It records the provider version, so the next `init` installs the same one.
- `terraform plan` works out the dependencies between resources (when one resource uses another, the one it uses is created first) and lists what each resource comes with, like the instance's root disk, `root_block_device`.
- `terraform apply` runs the plan again, shows it, and after `yes` applies it to your AWS account.
- `var.AMIS[var.AWS_REGION]` reads the `AMIS` map with the key `us-east-1`, so the instance gets the `us-east-1` AMI.
- After `apply`, `terraform.tfstate` holds the new instance and its ID.
- No default VPC? `apply` fails, because the instance has no subnet and the Region has no default VPC to launch it in. Run `aws ec2 create-default-vpc --region us-east-1`, and `terraform apply` again.

## Step 9: the instance type

In `instance.tf`, `instance_type = "t3.small"`, then `terraform plan`:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

The plan marks the instance with `~` (update in place): AWS can change the type of an existing instance. It stops the instance, changes the type and starts it again.

## Step 10: the AMI

In `vars.tf`, replace the `us-east-1` value in `AMIS` with an Ubuntu 24.04 AMI, `ami-0d6dd9e8265d48906` (`ubuntu-noble-24.04-amd64-server-20261023`), then `terraform apply`:

```text
Plan: 1 to add, 0 to change, 1 to destroy.
```

The plan marks the instance with `-/+` and says the `ami` *forces replacement*: an instance can't change its AMI, so Terraform deletes it and creates a new one. The new instance also gets `t3.small` from step 9.

> **AMI IDs change** with every release, and they differ per Region. To find the current one:
>
> ```bash
> # Amazon Linux 2023
> aws ssm get-parameters --region us-east-1 --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query 'Parameters[0].Value' --output text
> # Ubuntu 24.04
> aws ssm get-parameters --region us-east-1 --names /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --query 'Parameters[0].Value' --output text
> ```

## Steps 11–14: what destroy deletes

```bash
terraform destroy     # Plan: 0 to add, 0 to change, 1 to destroy.   type yes
```

The plan lists only `aws_instance.example`, and after `yes` Terraform reports `Destroy complete! Resources: 1 destroyed.` In the Console, `tf-example` is terminated, and `i'm still alive` is still running. Terminate it by hand.

## Answers

1. **Type vs. AMI:** some attributes can change on an existing resource, and Terraform updates it in place (`~`, `1 to change`). Others can't, like an instance's AMI, so Terraform replaces the resource (`-/+`, `1 to add` and `1 to destroy`). The resource's documentation, and the plan itself, say which attributes force a replacement.
2. **`terraform destroy`** deletes only the resources in its state file, the ones this configuration manages. `i'm still alive` was created in the Console, so it isn't in that state file, and Terraform doesn't touch it. (Terraform can take over an existing resource with `terraform import`, but that's for a later lesson.)
3. **`terraform.tfstate`** lists the resources Terraform manages, with their IDs and attributes. Terraform compares it with your files and with AWS to decide what to change. It can contain sensitive values, so it stays out of Git: the course repo's `.gitignore` excludes `terraform.tfstate*`.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
