# 5.02 Terraform Basic Commands – Lab 2: Your First EC2 Instance with Terraform

[⬅ Lab 1](tf-lab-1.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-2-solution/README.md)

In this lab you create a single EC2 instance with Terraform, then delete it:

| Setting | Value |
|---|---|
| Region | `us-east-1` |
| Availability Zone | `us-east-1a` |
| Instance type | `t3.micro` |
| VPC | the default VPC |

Before you start:
- [Lab 1](tf-lab-1.md).
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)): `aws sts get-caller-identity` shows your account.
- Your account has its default VPC in `us-east-1`.

> 💰 **Cost:** a `t3.micro` for a few minutes costs a few cents. Delete it at the end of the lab (step 7).

## Steps

Create a new folder called `lab2`, and save all the files below in it.

1. **Variables.** In `variables.tf`, define variables for the Region, the Availability Zone and the instance type, with the values from the table as defaults.
2. **Provider.** In `main.tf`, set the provider to AWS, and set its Region from your variable. See the [AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).
   > ⚠️ Don't put access keys in variables or in any file. The AWS provider uses the same credentials as the AWS CLI.
3. **EC2 instance.** In `main.tf`, add an [`aws_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resource with the instance type and the Availability Zone from your variables.
   - An instance needs an image (AMI). Find the latest **Amazon Linux 2023** AMI with an [`aws_ami`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) data source, instead of copying an AMI ID.
   - Give the instance the tag `Name = "tf-lab-2"`.
   - Without a subnet, AWS uses the default subnet of the Availability Zone, in the default VPC.
4. **Init.** Run `terraform init`. It downloads the AWS provider into the `.terraform` folder, and records its version in `.terraform.lock.hcl`.
5. **Plan.** Run `terraform plan`. Read what Terraform is going to create: it should be 1 resource.
6. **Apply.** Run `terraform apply`, check the plan again, and type `yes`. In the Console, open **EC2 → Instances** in `us-east-1`: `tf-lab-2` is running in `us-east-1a`.
7. **Clean up.** Run `terraform destroy`, and type `yes`.

## Questions

1. What does `terraform init` download, and where does it save it?
2. Run `terraform plan` again after `apply`. What does it show, and why?
3. Which file does Terraform use to remember which instance it created?

## What's next?

Compare your files with the **[Solution](tf-lab-2-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
