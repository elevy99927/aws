# 3.13 Containers: ECR, ECS & Fargate

> 📚 Based on the course slides *Welcome to the world of ECS – ECS clusters: getting things done with almighty ECS*, updated to the current AWS Console and features.

This chapter teaches how to run containers on AWS with **Amazon ECS** (Elastic Container Service): first on EC2 servers you manage, then behind a load balancer, then serverless with **AWS Fargate**, with your own images in **Amazon ECR**, and finally with automatic scaling.

## Chapter Contents

| # | Topic | Lab | Solution |
|---|-------|-----|----------|
| 1 | **ECS on EC2: Cluster, Task Definition and Service** – clusters, the ECS agent, task definitions, port mapping, services, IAM roles in ECS | [Lab 1](jb-lab-1.md) | [Solution](jb-lab-1-solution.md) |
| 2 | **ECS Service Load Balancing** – ALB, dynamic host port mapping, path-based routing | [Lab 2](jb-lab-2.md) | [Solution](jb-lab-2-solution.md) |
| 3 | **AWS Fargate** – serverless containers, `awsvpc` networking, EC2 vs. Fargate | [Lab 3](jb-lab-3.md) | [Solution](jb-lab-3-solution.md) |
| 4 | **Amazon ECR** – build, push and deploy your own image | [Lab 4](jb-lab-4.md) | [Solution](jb-lab-4-solution.md) |
| 5 | **ECS Service Auto Scaling** – scale tasks automatically with target tracking | [Lab 5](jb-lab-5.md) | [Solution](jb-lab-5-solution.md) |

Each lab has a solution in three ways: **Console (UI)**, **AWS CLI** and **Terraform**. The labs build on each other, so do them in order.

---

## Before You Start: Containers in One Minute

| Term | Meaning |
|------|---------|
| **Image** | A read-only package of an application with everything it needs (code, runtime, libraries), for example `traefik/whoami` |
| **Container** | A running instance of an image, isolated from other containers but sharing the host's OS kernel |
| **Registry** | A place to store and share images: Docker Hub, **Amazon ECR**, ECR Public |
| **Orchestrator** | Decides **where** containers run, restarts them when they fail, scales them and connects them to load balancers: **Amazon ECS**, Amazon EKS (Kubernetes) |


> ### [Click here for **Docker Tutorial**](https://github.com/elevy99927/docker)

---

### There are "50 ways to leave your lover"… and ~10 ways to run a container on AWS

| Service | In one line |
|---------|-------------|
| **EC2 + Docker** | Install Docker on an instance yourself. Full control, full responsibility |
| **Amazon ECS on EC2** | ECS orchestrates containers on EC2 instances in your account ([Lab 1](jb-lab-1.md)) |
| **Amazon ECS on Fargate** | ECS orchestrates containers on serverless compute, with no instances ([Lab 3](jb-lab-3.md)) |
| **Amazon EKS** | Managed Kubernetes, on EC2 or Fargate |
| **AWS App Runner** | Give it an image or code, and get an HTTPS web service |
| **AWS Lambda** (container image) | A function packaged as an image of up to 10 GB ([3.11](../3.06-lambda/README.md)) |
| **AWS Elastic Beanstalk** | A PaaS that can deploy Docker applications |
| **Amazon Lightsail containers** | Simple, fixed-price container hosting |
| **AWS Batch** | Batch jobs in containers, on EC2 or Fargate |
| **Red Hat OpenShift Service on AWS (ROSA)** | Managed OpenShift |

> **Exam tip:** "Run containers without managing servers" → **Fargate**. "Managed Kubernetes" → **EKS**. "Store and scan container images" → **ECR**.

---

[⬅ Previous: 3.12 DevOps & Microservices](../3.12-microservices/README.md) | [🏠 Home](../README.md) | [Next: 4.01 Network & Application Protection, Compliance ➡](../4.01-network-application-protection-compliance/README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
