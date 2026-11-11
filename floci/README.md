# Floci: AWS on Your Computer

[⬅ Back to the course](../README.md)

[Floci](https://floci.io/aws/) is a free, open-source (MIT) emulator of the AWS APIs. It runs as one Docker container on `http://localhost:4566`, and the AWS CLI, Terraform and the SDKs talk to it exactly as they talk to AWS, apart from the endpoint. EC2 instances become Docker containers, S3 buckets and DynamoDB tables really store data (in memory, by default), and nothing is billed.

Use it to develop and test the course's Terraform and CLI work in seconds, without an account, a bill, or resources left running overnight; then run the final version once against the real AWS. An emulator imitates the API, not the data center: see each lab's "What it isn't" notes.

## Labs

| # | Lab | What you do |
|---|---|---|
| 1 | **AWS on your computer** – install Floci, point the AWS CLI and Terraform at it, create a VPC and two EC2 instances with no AWS account, and SSH into an instance that is really a Docker container | [Lab 1](floci-lab-1.md) · [Solution](floci-lab-1-solution/README.md) |

Before you start: the [Terraform chapter](../5-terraform/5.02-terraform-basic-commands/README.md), Docker, the AWS CLI and Terraform.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
