# AWS LABS

## About This Course

A 4-week, hands-on introduction to the AWS Cloud. The course covers the foundational knowledge needed by anyone starting out with AWS, whether in technical, sales, management or finance roles. You don't need any prior cloud experience.

The course is organized into four modules, from cloud basics to running production workloads:

1. **Cloud Concepts**: what the cloud is, its service and deployment models, and the shared responsibility model.
2. **Foundations: Identity & Network**: the global infrastructure, identity and access management, secrets, and your own VPC.
3. **Services**, in two parts. **3A – Build a system**: compute, storage, S3, monitoring, serverless and containers. **3B – Production**: advanced networking, load balancing and auto scaling, DNS, content delivery and APIs, microservices and databases.
4. **Security, Cost & Architecture**: network and application protection, pricing, account and cost management, well-architected design, and support.

Each module contains a short README that lists its topics. Hands-on labs will use **Terraform** for Infrastructure as Code. Practice quizzes will be available soon on a companion website.

The course covers cloud fundamentals that overlap with entry-level AWS certification topics. It is free and open to everyone, but it does not map one-to-one to any AWS exam and does not guarantee exam results. Use the official resources below to check the current exam scope.

### Basic and Advanced labs

Do every lab in your own AWS account. The examples use **`us-east-1`**, S3 buckets named **`jblabs-…`** and IAM users named **`lab-…`**.

- **Basic labs** (and Parts A–C of a basic lab) cover the core of each topic.
- **Advanced labs** (and advanced parts of basic labs) go deeper. They are marked **(Advanced)** in their heading.

> **Disclaimer:** This is an independent course. It is **not** an official AWS course, and it is not affiliated with, endorsed by or sponsored by Amazon Web Services (AWS) or any AWS certification program. AWS and all related names are trademarks of Amazon.com, Inc. or its affiliates. This course does not contain any actual exam content.

---

## Course Modules

| Module | # | Chapter |
|--------|---|---------|
| 0 – Prerequisites | 00 | [Getting Started: AWS Console & AWS CLI](00-getting-started/README.md) |
| 1 – Cloud Concepts | 1.01 | [What is Cloud Computing?](1.01-what-is-cloud-computing/README.md) |
|  | 1.02 | [Cloud Models](1.02-cloud-models/README.md) |
|  | 1.03 | [Shared Responsibility Model](1.03-shared-responsibility-model/README.md) |
| 2 – Foundations: Identity & Network | 2.01 | [AWS Global Infrastructure](2.01-global-infrastructure/README.md) |
|  | 2.02 | [Identity and Access Management (AWS IAM)](2.02-iam/README.md) |
|  | 2.03 | [Secrets Management](2.03-secrets-management/README.md) |
|  | 2.04 | [VPC and Networking](2.04-vpc-and-networking/README.md) |
| 3A – Services: Build a System | 3.01 | [Compute: Amazon EC2](3.01-ec2/README.md) |
|  | 3.02 | [Storage: EBS & EFS](3.02-storage/README.md) |
|  | 3.03 | [Amazon S3](3.03-s3/README.md) |
|  | 3.04 | [Monitoring & Auditing](3.04-monitoring/README.md) |
|  | 3.05 | [Serverless: AWS Lambda](3.05-lambda/README.md) |
|  | 3.06 | [Containers: ECR, ECS & Fargate](3.06-containers/README.md) |
| 3B – Services: Production | 3.07 | [Advanced VPC](3.07-advanced-vpc/README.md) |
|  | 3.08 | [Load Balancing & Auto Scaling](3.08-load-balancing-auto-scaling/README.md) |
|  | 3.09 | [Amazon Route 53](3.09-route53/README.md) |
|  | 3.10 | [CloudFront & API Gateway](3.10-cloudfront-api-gateway/README.md) *(coming soon)* |
|  | 3.11 | [Project: Simple Website on Lambda](simple-website-lambda/) |
|  | 3.12 | [DevOps & Microservices](3.12-microservices/README.md) *(coming soon)* |
|  | 3.13 | [Databases](3.13-databases/README.md) |
| 4 – Security, Cost & Architecture | 4.01 | [Network & Application Protection, Compliance](4.01-network-application-protection-compliance/README.md) |
|  | 4.02 | [EC2 Pricing Models](4.02-ec2-pricing-models/README.md) |
|  | 4.03 | [Account & Cost Management](4.03-accounts-and-cost-management/README.md) |
|  | 4.04 | [Architecting in the Cloud](4.04-well-architected-cloud/README.md) |
|  | 4.05 | [Support Plans & Course Review](4.05-support-plans-and-review/README.md) |

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
