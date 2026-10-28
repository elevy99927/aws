# 5.02 Terraform Basic Commands – Lab 2 Solution

[⬅ Lab 2](../tf-lab-2.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the three files in this folder:

| File | What it holds |
|---|---|
| [`variables.tf`](variables.tf) | `region`, `availability_zone` and `instance_type`, with the lab's values as defaults |
| [`main.tf`](main.tf) | The AWS provider, the `aws_ami` data source (the latest Amazon Linux 2023) and the `aws_instance` resource |
| [`outputs.tf`](outputs.tf) | The instance ID, its Availability Zone and the AMI name, printed after `apply` |

Notes on `main.tf`:
- The `provider "aws"` block sets only the Region. The credentials come from the AWS CLI (`aws login` or a profile), so no key is ever written in a file, and none ends up in Git or in the state file.
- `data "aws_ami"` searches Amazon's own images (`owners = ["amazon"]`) for the newest name that matches `al2023-ami-2023.*-x86_64`. The AMI ID differs per Region and changes with every release, so looking it up is safer than copying it.
- `aws_instance` has no `subnet_id`. With `availability_zone = "us-east-1a"`, AWS uses the default subnet of that Availability Zone, in the default VPC.

## Run it

```bash
cd tf-lab-2-solution      # or your own lab2 folder
terraform init
terraform plan
terraform apply           # type yes
terraform destroy         # type yes, at the end of the lab
```

## Answers

1. **`terraform init`** downloads the providers that the configuration needs, here `hashicorp/aws`, into the `.terraform` folder. It records the exact version and its checksums in `.terraform.lock.hcl`, so the next `init` installs the same version.
2. **`terraform plan` after `apply`** shows *No changes. Your infrastructure matches the configuration.* Terraform compares your files with the real resources it recorded, and there is nothing left to do.
3. **`terraform.tfstate`.** Terraform records every resource it created there, with its ID. Don't edit it or delete it by hand, and don't commit it to Git: it can contain sensitive values.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
