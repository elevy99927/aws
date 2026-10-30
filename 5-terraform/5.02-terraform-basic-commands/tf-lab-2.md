# 5.02 Terraform Basic Commands – Lab 2: Create an EC2 Instance with Terraform

[⬅ Lab 1](tf-lab-1.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-2-solution/README.md) | [Lab 3 ➡](tf-lab-3.md)

**▶ Video walkthrough** (10 min):

[![Video: Terraform – Create your first EC2 instance with Terraform](https://img.youtube.com/vi/P-M8K8cQGtU/maxresdefault.jpg)](https://youtu.be/P-M8K8cQGtU)

In this lab you create an EC2 instance with Terraform, and compare a change that updates the existing instance with one that replaces it. Then you see what `terraform destroy` deletes, and what it doesn't.

| Setting | Value |
|---|---|
| Region | `us-east-1` |
| Instance type | `t2.micro`, later `t3.small` |
| VPC | the default VPC |

Before you start:
- [Lab 1](tf-lab-1.md).
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)): `aws sts get-caller-identity` shows your account.

> 💰 **Cost:** a `t2.micro` or `t3.small` for the length of the lab costs a few cents. Delete everything at the end (steps 12 and 14).

## A default VPC

The instance in this lab has no network settings, so AWS launches it in the Region's **default VPC**. There are two options:
1. **You have a default VPC** in `us-east-1`. Most accounts do.
2. **You don't have one**, for example because it was deleted. Create it with one command:

```bash
aws ec2 create-default-vpc --region us-east-1
```

To check which option is yours:

```bash
aws ec2 describe-vpcs --region us-east-1 --filters Name=is-default,Values=true --query 'Vpcs[].VpcId' --output text
```

A `vpc-…` ID means you have one. Empty output means you don't. You can also skip the check: if `terraform apply` (step 7) fails because there's no default VPC, create it then, and run `apply` again. If you create it in this lab, you delete it at the end (step 14): from Lab 3 on, Terraform creates the VPC.

## Steps

1. **Create a new folder** called `tf-lab-2`, and save all the files of this lab in it. Terraform reads all the `.tf` files in a folder together: the file names only help you organize the code.
2. **Create two files:**
   - `vars.tf`: the variables `AWS_ACCESS_KEY`, `AWS_SECRET_KEY` and `AWS_SESSION_TOKEN` with `default = null`, the variable `AWS_REGION` with the default `us-east-1`, and a map variable `AMIS` with an Amazon Linux 2023 AMI ID for each Region.
   - `provider.tf`: the AWS provider, with its keys and Region taken from your variables.

   > ⚠️ Never write your keys in a file. With `default = null`, the provider uses your `aws login` session. To use access keys instead, set them in the shell: `export TF_VAR_AWS_ACCESS_KEY=…` and `export TF_VAR_AWS_SECRET_KEY=…`.

3. **Run `terraform init`.**

   > **Providers.** A provider is a plugin that lets Terraform talk to one platform's API: AWS, Azure, Google Cloud, Kubernetes, GitHub, and many more. `terraform init` downloads the providers your files ask for from the [Terraform Registry](https://registry.terraform.io) into the `.terraform` folder, and records their versions in `.terraform.lock.hcl`, the dependency lock file. Each provider's documentation is in the Registry. For AWS, open the [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs): the tree on the left lists every resource, and each resource page, like [`aws_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance), starts with **Example Usage**.

4. **Create `instance.tf`** with one EC2 instance:

   ```hcl
   resource "aws_instance" "example" {
     ami           = var.AMIS[var.AWS_REGION]
     instance_type = "t2.micro"
   }
   ```

   Add a tag to it: `Name = "tf-example"`. `var.AMIS[var.AWS_REGION]` reads the map with the Region as the key, so in `us-east-1` it returns the `us-east-1` AMI.
5. **Run `terraform plan`.** Read the plan, and focus on its last line: `Plan: 1 to add, 0 to change, 0 to destroy.`
6. **Run `terraform apply`**, and type `yes`.

   > **The state file.** After `apply`, the folder has a new file: `terraform.tfstate`. It lists the resources Terraform manages, with their IDs and attributes. Every `plan` and `apply` compares three things: your files, the state file, and the real resources in AWS. Never edit it by hand, and never commit it to Git: it can contain sensitive values.

7. **No default VPC?** If `apply` fails because there's no default VPC, run `aws ec2 create-default-vpc --region us-east-1`, and then `terraform apply` again.
8. **Open the AWS Console**, **EC2 → Instances** in `us-east-1`. Find `tf-example`: its instance type is `t2.micro`.
9. **Change the instance type** in `instance.tf` to `t3.small`, and run `terraform plan`. The last line: `Plan: 0 to add, 1 to change, 0 to destroy.` Terraform can change the type of the existing instance.
10. **Change the AMI**: in `vars.tf`, replace the `us-east-1` AMI with an Ubuntu 24.04 AMI (see the solution), and run `terraform apply`. The last line: `Plan: 1 to add, 0 to change, 1 to destroy.` An instance can't change its AMI, so Terraform deletes it and creates a new one. Type `yes`.
11. **Create an instance by hand**, in the Console: **EC2 → Launch instance**, the name `i'm still alive`, Amazon Linux 2023, `t2.micro`, and **Proceed without a key pair**. In **Network settings**, keep the default VPC and clear **Allow SSH traffic from**: you won't connect to this instance. Choose **Launch instance**.
12. **Run `terraform destroy`**, and read the output before you type `yes`: `Plan: 0 to add, 0 to change, 1 to destroy.` Which instance is on the list?
13. **Open the Console** again. `tf-example` is terminated, and `i'm still alive` is still running.
14. **Clean up:** select `i'm still alive`, and choose **Instance state → Terminate (delete) instance**. Wait until it's terminated. Then:

    **Delete the default VPC, if you created it in step 7:** in the Console, open **VPC → Your VPCs**, select the default VPC (its range is `172.31.0.0/16`), and choose **Actions → Delete VPC**. The dialog lists what's deleted with it: its subnets and its internet gateway. Check **I acknowledge that I want to delete my default VPC**, type `delete default vpc`, and choose **Delete**. If your account had a default VPC before this lab, keep it. From now on, we create the VPC with Terraform.

## Questions

1. Why did the instance type change show `1 to change`, but the AMI change `1 to add` and `1 to destroy`?
2. Why didn't `terraform destroy` delete `i'm still alive`?
3. What does `terraform.tfstate` hold, and why should it stay out of Git?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-2-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
