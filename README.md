# AWS LABS

## About This Course

A 4-week, hands-on introduction to the AWS Cloud. The course covers the foundational knowledge needed by anyone starting out with AWS, whether in technical, sales, management or finance roles. You don't need any prior cloud experience.

The course is organized into four domains:

1. **Cloud Concepts**: what the cloud is, its value, its service and deployment models, and well-architected design.
2. **Security & Compliance**: the shared responsibility model, identity and access management, network protection and compliance.
3. **Technology & Services**: the global infrastructure and the core compute, storage, database and monitoring services.
4. **Billing, Pricing & Support**: pricing models, cost management tools and support plans.

Each module contains a short README that lists its topics. Hands-on labs will use **Terraform** for Infrastructure as Code. Practice quizzes will be available soon on a companion website.

The course covers cloud fundamentals that overlap with entry-level AWS certification topics. It is free and open to everyone, but it does not map one-to-one to any AWS exam and does not guarantee exam results. Use the official resources below to check the current exam scope.

### Basic and Advanced labs

- **Basic labs** (and Parts A–C of a basic lab) are designed to work in a **restricted classroom AWS account**: work only in **`us-east-1`**, name S3 buckets **`jblabs-…`**, and name IAM users **`lab-…`**.
- **Advanced labs** (and advanced parts of basic labs) are marked with ⚠️. They may not work in every AWS account because of SCPs (Service Control Policies) or other restrictions, so we recommend doing them in your own private AWS account.

> **Disclaimer:** This is an independent course. It is **not** an official AWS course, and it is not affiliated with, endorsed by or sponsored by Amazon Web Services (AWS) or any AWS certification program. AWS and all related names are trademarks of Amazon.com, Inc. or its affiliates. This course does not contain any actual exam content.

---

## Course Modules

| Week | # | Module |
|------|---|--------|
| 0 – Prerequisites | 00 | [Getting Started: AWS Console & AWS CLI](00-getting-started/README.md) |
| 1 – Cloud Concepts | 1.01 | [What is Cloud Computing?](1.01-what-is-cloud-computing/README.md) |
|  | 1.02 | [Cloud Models](1.02-cloud-models/README.md) |
|  | 1.03 | [Architecting in the Cloud](1.03-well-architected-cloud/README.md) |
|  | 1.04 | [Shared Responsibility Model](1.04-shared-responsibility-model/README.md) |
| 2 – Security & Compliance | 2.01 | [Identity and Access Management (AWS IAM)](2.01-iam/README.md) |
|  | 2.02 | [Secrets Management](2.02-secrets-management/README.md) |
|  | 2.03 | [Network & Application Protection, Compliance](2.03-network-application-protection-compliance/README.md) |
| 3 – Technology & Services | 3.01 | [AWS Global Infrastructure](3.01-global-infrastructure/README.md) |
|  | 3.02 | [VPC Basics](3.02-vpc-basics/README.md) |
|  | 3.03 | [Compute: Amazon EC2](3.03-ec2/README.md) |
|  | 3.04 | [Storage: EBS & EFS](3.04-storage/README.md) |
|  | 3.05 | [Amazon S3](3.05-s3/README.md) |
|  | 3.06 | [Containers: ECR, ECS & Fargate](3.06-containers/README.md) |
|  | 3.07 | [Databases](3.07-databases/README.md) |
|  | 3.08 | [Advanced VPC](3.08-advanced-vpc/README.md) |
|  | 3.09 | [Monitoring & Auditing](3.09-monitoring/README.md) |
|  | 3.10 | [Advanced EC2: Load Balancing, Auto Scaling & Route 53](3.10-advanced-ec2/README.md) |
|  | 3.11 | [Serverless: AWS Lambda](3.11-lambda/README.md) |
| 4 – Billing, Pricing & Support | 4.01 | [EC2 Pricing Models](4.01-ec2-pricing-models/README.md) |
|  | 4.02 | [Account & Cost Management](4.02-accounts-and-cost-management/README.md) |
|  | 4.03 | [Support Plans & Course Review](4.03-support-plans-and-review/README.md) |

---

## Free Official AWS Learning Resources

- [AWS Skill Builder](https://skillbuilder.aws/): free digital training from AWS, including *AWS Cloud Practitioner Essentials*
- [AWS Certified Cloud Practitioner (CLF-C02) Exam Guide](https://docs.aws.amazon.com/aws-certification/latest/cloud-practitioner-02/cloud-practitioner-02.html)
- [AWS Certified Cloud Practitioner: official page and sample questions](https://aws.amazon.com/certification/certified-cloud-practitioner/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Free Tier](https://aws.amazon.com/free/)

---

## Tools Installation

- **AWS CLI**: [Installing or updating the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Terraform**: [Install Terraform](https://developer.hashicorp.com/terraform/install)
- **Floci** (a free local AWS emulator for practicing without cloud costs): [floci.io](https://floci.io/) | [GitHub](https://github.com/floci-io/floci)

---

## Open in Google Cloud Shell

You can directly open this repository in Google Cloud Shell to start exploring the examples:

[![Open in Google Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https://github.com/elevy99927/aws)


---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
