# 5.02 Terraform Basic Commands

## Chapter Contents

| # | Lab | Steps |
|---|-----|-------|
| 1 | **Built-in Functions in `terraform console`** – try Terraform's built-in functions at an interactive prompt: numbers, Base64, text, lists, maps and CIDR ranges. No AWS account and no files needed | [Lab 1](tf-lab-1.md) · [Solution](tf-lab-1-solution.md) · [▶ Video](https://youtu.be/1il7nk5QQck) |
| 2 | **Create an EC2 Instance with Terraform** – `vars.tf` with an AMI map, the AWS provider and an `aws_instance` in the default VPC; `init`, `plan` and `apply`, a change in place and a replacement, and what `destroy` deletes | [Lab 2](tf-lab-2.md) · [Solution](tf-lab-2-solution/README.md) · [▶ Video](https://youtu.be/Yse_Sl8g8_A) |

Before you start: [5.01 Install Terraform](../5.01-install-terraform/README.md).

## From a shell variable to a Terraform variable

A shell variable named `TF_VAR_<name>` gives a value to the Terraform variable `<name>`, which the code reads as `var.<name>`:

![export TF_VAR_AWS_ACCESS_KEY=Aa123456 in the shell; Terraform removes the TF_VAR_ prefix and finds variable "AWS_ACCESS_KEY" in vars.tf; the provider block in main.tf reads it as var.AWS_ACCESS_KEY, which is "Aa123456". Without the variable block, Terraform ignores TF_VAR_AWS_ACCESS_KEY; without a value and no default, terraform plan asks: Enter a value](images/tf-var-flow.jpg)

<sub>Diagram source: [images/tf-var-flow.drawio](images/tf-var-flow.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

---

[⬅ Previous: 5.01 Install Terraform](../5.01-install-terraform/README.md) | [🏠 Home](../../README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
