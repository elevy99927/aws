# 5.02 Terraform Basic Commands – Lab 3: A VPC, a Subnet, Two EC2 Instances and an S3 Bucket

[⬅ Lab 2](tf-lab-2.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-3-solution/README.md)

In Lab 2, the instance went into a default VPC made by hand, which you deleted at the end. From now on, Terraform creates the network as code. In this lab you build a small infrastructure with Terraform: your own VPC, a subnet inside it, two EC2 instances in that subnet, and an S3 bucket. You connect the resources to each other, and see how Terraform works out the order to create them.

| Resource | Settings |
|---|---|
| VPC | `10.0.0.0/16`, the name `tf-lab-3-vpc` |
| Subnet | `10.0.1.0/24` in `us-east-1a`, inside the VPC, the name `tf-lab-3-subnet` |
| EC2 instance 1 | `t2.micro`, in the subnet, the name `tf-lab-3-web-1` |
| EC2 instance 2 | `t3.micro`, in the subnet, the name `tf-lab-3-web-2` |
| S3 bucket | `s3-lab-<yourname>`, for example `s3-lab-dana` |

Region: **`us-east-1`**.

Before you start:
- [Lab 2](tf-lab-2.md): this lab reuses its `vars.tf` and `provider.tf`.
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)).

You don't need a default VPC for this lab: the instances go into your own VPC.

> 💰 **Cost:** two small instances for the length of the lab cost a few cents. A VPC, a subnet and an empty bucket cost nothing. At the end, either destroy everything (step 10), or keep it for the next lab.

## Steps

1. **Create a new folder** called `tf-lab-3`, and copy `vars.tf` and `provider.tf` from Lab 2 into it.
2. **The VPC.** In a new file, `vpc.tf`, add an [`aws_vpc`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) resource with the range `10.0.0.0/16` and the tag `Name = "tf-lab-3-vpc"`. Start from the **Example Usage** on its page.
3. **The subnet.** In `vpc.tf`, add an [`aws_subnet`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) resource in `us-east-1a`, with the range `10.0.1.0/24` and the tag `Name = "tf-lab-3-subnet"`. Connect it to your VPC: set its `vpc_id` to your VPC's ID, as in the Example Usage, instead of typing an ID.
4. **The two EC2 instances.** In `instance.tf`, add two [`aws_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resources, a `t2.micro` and a `t3.micro`, with the AMI from the `AMIS` map, as in Lab 2. Put both in your subnet with `subnet_id`, and give them the names from the table.
5. **The S3 bucket.** In `s3.tf`, add an [`aws_s3_bucket`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) resource with the name `s3-lab-<yourname>`. Bucket names are global across all AWS accounts, so use your own name, in lowercase.
6. **Run `terraform init`**, because this is a new folder, and then **`terraform plan`**. Read the plan: how many resources will it create, and which values does it show as `(known after apply)`?
7. **Run `terraform apply`**, and type `yes`. Watch the order in which Terraform creates the resources.
8. **Open the AWS Console** in `us-east-1`, and find what you created:
   - **VPC → Your VPCs:** `tf-lab-3-vpc`, and under **Subnets**, `tf-lab-3-subnet`;
   - **EC2 → Instances:** `tf-lab-3-web-1` and `tf-lab-3-web-2`, in `tf-lab-3-subnet`;
   - **S3 → Buckets:** `s3-lab-<yourname>`.
9. **A problem to think about:** how would you connect to these instances? Look at their details in the Console: do they have a public IP address? A key pair? What else is missing?
10. **Choose:**
    - **Delete everything:** run `terraform destroy`, and type `yes`.
    - **Keep it for the next lab,** where we use Terraform **outputs** to print the information we need about these resources. The two instances keep costing money until you destroy them.

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
