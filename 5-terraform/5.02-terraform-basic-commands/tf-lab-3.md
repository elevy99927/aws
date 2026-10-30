# 5.02 Terraform Basic Commands – Lab 3: A VPC, a Subnet, Two EC2 Instances and an S3 Bucket

[⬅ Lab 2](tf-lab-2.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-3-solution/README.md)

[![Video: Terraform – Connecting the dots](https://img.youtube.com/vi/ftapMnWxOw4/maxresdefault.jpg)](https://youtu.be/ftapMnWxOw4)

In Lab 2, the instance went into a default VPC made by hand, which you deleted at the end. From now on, Terraform creates the network as code. In this lab you build a small infrastructure with Terraform: your own VPC, a subnet inside it, two EC2 instances in that subnet, and an S3 bucket. You connect the resources to each other, and see how Terraform works out the order to create them.

| Resource | Settings |
|---|---|
| VPC | `10.0.0.0/16`, the name `training-vpc` |
| Subnet | `10.0.1.0/24` in `us-east-1a`, inside the VPC, the name `training-subnet-1a` |
| EC2 instance 1 | `t2.micro`, in the subnet, the name `my-tf-web-1` |
| EC2 instance 2 | `t3.micro`, in the subnet, the name `my-tf-web-2` |
| S3 bucket | `s3-lab-<yourname>-<random number>`, for example `s3-lab-dana-4821` |

Region: **`us-east-1`**.

Before you start:
- [Lab 2](tf-lab-2.md): this lab reuses its `vars.tf` and `provider.tf`.
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)).

You don't need a default VPC for this lab: the instances go into your own VPC.

> 💰 **Cost:** two small instances for the length of the lab cost a few cents. A VPC, a subnet and an empty bucket cost nothing. At the end, either destroy everything (step 10), or keep it for the next lab.

## Steps

1. **Create a new folder** called `tf-lab-3`.
   - Copy `vars.tf` and `provider.tf` from Lab 2 into it.
2. **The VPC.** In a new file, `vpc.tf`, add an [`aws_vpc`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) resource:
   - set the range `10.0.0.0/16` and the tag `Name = "training-vpc"`;
   - start from the **Example Usage** on its page.
3. **The subnet.** In `vpc.tf`, add an [`aws_subnet`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) resource in `us-east-1a`:
   - set the range `10.0.1.0/24` and the tag `Name = "training-subnet-1a"`;
   - connect it to your VPC: set its `vpc_id` to your VPC's ID, as in the Example Usage.
4. **The two EC2 instances.** In `instance.tf`, add two [`aws_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resources:
   - a `t2.micro` and a `t3.micro`, with the AMI from the `AMIS` map, as in Lab 2;
   - put both in your subnet with `subnet_id`;
   - name them `my-tf-web-1` and `my-tf-web-2`.
5. **The S3 bucket.** In `s3.tf`, add an [`aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) resource:
   - name it `s3-lab-<yourname>-<random number>`, in lowercase, for example `s3-lab-dana-4821`;
   - bucket names are global across all AWS accounts: the random number keeps your name from clashing with someone else's.
6. **Run `terraform init`**, because this is a new folder, and then **`terraform plan`**. Read the plan:
   - how many resources will it create?
   - which values does it show as `(known after apply)`?
7. **Run `terraform apply`**, and type `yes`.
   - Watch the order in which Terraform creates the resources.
8. **Open the AWS Console** in `us-east-1`, and find what you created:
   - **VPC → Your VPCs:** `training-vpc`, and under **Subnets**, `training-subnet-1a`;
   - **EC2 → Instances:** `my-tf-web-1` and `my-tf-web-2`, in `training-subnet-1a`;
   - **S3 → Buckets:** `s3-lab-<yourname>-<random number>`.
9. **A problem to think about:** how would you connect to these instances? Look at their details in the Console:
   - do they have a public IP address?
   - a key pair?
   - what else is missing?
10. **Choose:**
    - **Delete everything:** run `terraform destroy`, and type `yes`.
    - **Keep it for the next lab,** where we use Terraform **outputs** to print the information we need about these resources.
    - The two instances keep costing money until you destroy them.

## Questions

1. In the plan, why is the subnet's `vpc_id` shown as `(known after apply)`?
2. In which order did Terraform create the resources, and why in that order?
3. Why can't you connect to the instances, and what's missing?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-3-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
