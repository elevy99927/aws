# 5.02 Terraform Basic Commands – Lab 3 Solution

[⬅ Lab 3](../tf-lab-3.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the five files in this folder:

| File | What it holds |
|---|---|
| [`vars.tf`](vars.tf) | The same as in Lab 2: the credential variables, `AWS_REGION` and the `AMIS` map |
| [`provider.tf`](provider.tf) | The same as in Lab 2: the AWS provider |
| [`vpc.tf`](vpc.tf) | The VPC `training-vpc`, and the subnet `training-subnet-1a` inside it |
| [`instance.tf`](instance.tf) | The two instances, `my-tf-web-1` and `my-tf-web-2`, in the subnet |
| [`s3.tf`](s3.tf) | The bucket `s3-lab-yourname-1234` |

## Steps 2–3: the VPC and the subnet

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "training-vpc" }
}

resource "aws_subnet" "subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "training-subnet-1a" }
}
```

- The VPC is the [Example Usage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) with tags: a range and a name.
- `aws_vpc.main.id` is a **reference**: the type, the name we gave the resource, and one of its attributes. It connects the subnet to the VPC, the same way as the subnet's [Example Usage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet).
- The subnet's range, `10.0.1.0/24`, must be inside the VPC's range, `10.0.0.0/16`.

## Step 4: the two instances

```hcl
resource "aws_instance" "web_1" {
  ami           = var.AMIS[var.AWS_REGION]
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1a.id
  tags = { Name = "my-tf-web-1" }
}
```

`web_2` is the same, with `t3.micro` and `my-tf-web-2`. `subnet_id` puts each instance in our subnet, so it doesn't need a default VPC. The [`aws_instance` page](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) builds the same chain in its *Network and credit specification example*: a VPC, a subnet in it, and an instance connected to that subnet through a network interface. We connect it more simply, with `subnet_id`.

## Step 5: the bucket

```hcl
resource "aws_s3_bucket" "lab" {
  bucket = "s3-lab-yourname-1234"
}
```

The [Example Usage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) adds tags, which are optional. Bucket names are global across all AWS accounts: if the name is taken, `apply` fails with `BucketAlreadyExists`, so use your own name and a random number. The bucket doesn't refer to any other resource.

## Step 6: init and plan

`terraform init` installs the AWS provider in the new folder:

```text
- Installed hashicorp/aws v6.71.0 (signed by HashiCorp)
Terraform has been successfully initialized!
```

`terraform plan` (trimmed):

```text
  # aws_instance.web_1 will be created
      + instance_type = "t2.micro"
      + subnet_id     = (known after apply)
  # aws_instance.web_2 will be created
      + instance_type = "t3.micro"
      + subnet_id     = (known after apply)
  # aws_s3_bucket.lab will be created
      + bucket        = "s3-lab-student-2823"
  # aws_subnet.subnet_1a will be created
      + cidr_block    = "10.0.1.0/24"
      + vpc_id        = (known after apply)
  # aws_vpc.main will be created
      + cidr_block    = "10.0.0.0/16"

Plan: 5 to add, 0 to change, 0 to destroy.
```

The plan lists the resources in alphabetical order, not in the order it creates them. `(known after apply)` marks values that AWS sets only when it creates the resource, like IDs.

## Step 7: apply

The real run, with the bucket `s3-lab-student-2823`. The IDs are masked:

```text
aws_vpc.main: Creating...
aws_s3_bucket.lab: Creating...
aws_vpc.main: Creation complete after 3s [id=vpc-0a1b2c3d4e5f60001]
aws_subnet.subnet_1a: Creating...
aws_subnet.subnet_1a: Creation complete after 1s [id=subnet-0a1b2c3d4e5f60001]
aws_s3_bucket.lab: Creation complete after 4s [id=s3-lab-student-2823]
aws_instance.web_2: Creating...
aws_instance.web_1: Creating...
aws_instance.web_1: Creation complete after 15s [id=i-0a1b2c3d4e5f60001]
aws_instance.web_2: Creation complete after 15s [id=i-0a1b2c3d4e5f60002]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

- The VPC and the bucket start together: they don't depend on anything.
- The subnet starts only after the VPC is ready, and the two instances only after the subnet.
- Each run can show a different order between independent resources, like the two instances.

## Step 8: in the Console

- **VPC → Your VPCs →** `training-vpc` → **Resource map**: one subnet, `training-subnet-1a` in `us-east-1a`, with the VPC's main route table. **Network Connections (0)**: no internet gateway.
- **EC2 → Instances:** `my-tf-web-1` (`t2.micro`) and `my-tf-web-2` (`t3.micro`), both in `us-east-1a`, with no **Public IPv4 DNS** and no **Public IPv4 address**.
- An instance's **Details**: its VPC is `training-vpc` and its subnet is `training-subnet-1a`. It has only a private address in the subnet's range (in this run, `10.0.1.12`).
- **S3 → Buckets:** `s3-lab-<yourname>-<random number>` in `us-east-1`.

## Step 9: why we can't connect

To connect with SSH from our computer, an instance needs:

- **a public IP address:** ours have only private ones;
- **a route to the internet:** our VPC has no internet gateway, and its route table has no route out;
- **a key pair:** we didn't give the instances one;
- **a security group that allows SSH:** they use the VPC's default security group, which allows no traffic from the internet.

## Step 10: destroy, or keep

```bash
terraform destroy     # type yes
```

```text
Plan: 0 to add, 0 to change, 5 to destroy.
...
aws_subnet.subnet_1a: Destroying... [id=subnet-0a1b2c3d4e5f60001]
aws_vpc.main: Destroying... [id=vpc-0a1b2c3d4e5f60001]

Destroy complete! Resources: 5 destroyed.
```

Destroy goes in the reverse order: the instances first, then the subnet, and the VPC last. The bucket depends on nothing, so Terraform deletes it right away, together with the instances. To keep the resources for the next lab, skip the destroy: the two instances keep costing money until you destroy them.

## Answers

1. **`vpc_id` is `(known after apply)`** because the VPC doesn't exist yet when Terraform plans. AWS gives the VPC its ID only when it creates it, so Terraform fills in the subnet's `vpc_id` during the apply.
2. **The order:** the VPC and the bucket first, at the same time; then the subnet; then the two instances. Each reference (`aws_vpc.main.id`, `aws_subnet.subnet_1a.id`) is a dependency, and Terraform creates a resource only after the resources it refers to. Resources with no dependency between them, like the bucket and the VPC, are created in parallel.
3. **We can't connect** because the instances have no public IP address, the VPC has no internet gateway or route to the internet, there's no key pair, and the default security group doesn't allow SSH. We add these in the next labs, and use Terraform **outputs** to print what we need, like the IP address.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
