# 3.06 Containers – jb-lab-4: Amazon ECR

[⬅ jb-lab-3](jb-lab-3.md) | [⬅ Back to 3.06 Containers](README.md) | [jb-lab-5 ➡](jb-lab-5.md)

> 📚 ECR appears on the agenda of the course slides (*ECS clusters – getting things done with almighty ECS*). This page covers it hands-on, including the "ECS IAM" agenda item: how a task gets permission to pull your image.

---

## 1. What is Amazon ECR?

**Amazon Elastic Container Registry (ECR)** is AWS's managed, private **container image registry**. You **push** images to it from your computer or CI pipeline, and ECS, EKS, Lambda or EC2 **pull** them from it.

| Concept | Meaning |
|---------|---------|
| **Registry** | One per account per Region: `<account-id>.dkr.ecr.<region>.amazonaws.com` |
| **Repository** | Holds the versions of **one** image, for example `jb-web` |
| **Image tag** | A human-friendly name for a version, for example `v1`, `v2`, `latest` |
| **Image digest** | The image's unique, unchangeable ID (`sha256:…`) |
| **Image URI** | `<account-id>.dkr.ecr.us-east-1.amazonaws.com/jb-web:v1`, which is what goes into the task definition |

## 2. Features Worth Knowing

| Feature | What it does |
|---------|--------------|
| **IAM authentication** | `docker login` with a token from `aws ecr get-login-password`, valid for **12 hours** |
| **Image scanning** | Finds known vulnerabilities (CVEs) in your images: *basic* scanning on push, or *enhanced* continuous scanning with Amazon Inspector |
| **Tag immutability** | Prevents overwriting an existing tag, so `v1` always means the same image |
| **Lifecycle policies** | Delete old images automatically, for example "keep only the last 5" |
| **Encryption** | Images are encrypted at rest (AES-256 or KMS) |
| **Replication** | Copy images to other Regions or accounts |
| **ECR Public** | A public registry (`public.ecr.aws`). This lab's base image, `public.ecr.aws/nginx/nginx`, comes from there |
| **Pricing** | About **$0.10 per GB-month** of storage. Pulling to ECS in the same Region is free |

## 3. How ECS Pulls a Private Image

```
  your laptop                           Amazon ECR                         ECS (Fargate)
 docker build ──► docker push ──► [ jb-web:v1, jb-web:v2 ] ◄── pull ── task (uses the task EXECUTION role)
                (IAM credentials)                                    ecsTaskExecutionRole:
                                                                     AmazonECSTaskExecutionRolePolicy
```

The **task execution role** (see [jb-lab-1](jb-lab-1.md#iam-roles-in-ecs)) gives ECS permission to get an ECR token and download the image layers. Your application code never needs these permissions.

## 4. CPU Architecture Matters

An image is built for a specific CPU architecture. If you build on an **Apple Silicon (ARM)** Mac and run on **x86** Fargate, the task fails to start. Either:

- build for the target: `docker build --platform linux/amd64 …`, or
- run the task on **ARM64** (Graviton) Fargate, which is cheaper, and build for `linux/arm64`.

---

## 🧪 jb-lab-4 (Basic): Build, Push and Deploy Your Own Image

> 💰 **Cost:** ECR storage for a 29 MB image is fractions of a cent. The ALB and Fargate tasks from jb-lab-3 cost about **$0.06/hour**. Up to 2 hours ≈ **$0.12**.

**Goal:** Build a small web image, push it to a **private ECR repository**, run it on **Fargate** behind the ALB, and then roll out a new version.

**Prerequisite:** the cluster `jb-ecs-fargate`, the ALB `jb-ecs-alb` and the security groups from [jb-lab-3](jb-lab-3.md). You also need **Docker** locally. AWS CloudShell has Docker too.

**Files:** [`artifacts/jb-lab-4/`](artifacts/jb-lab-4/)

| File | What it is |
|------|------------|
| [`Dockerfile`](artifacts/jb-lab-4/Dockerfile) | nginx from ECR Public, plus our page. `--build-arg VERSION=…` sets the version |
| [`index.html`](artifacts/jb-lab-4/index.html) | The page: *Hello from Amazon ECR – version vX* |

> 🏫 **Classroom account rules:** work only in **`us-east-1`**, and name your resources with the **`jb-`** prefix.

### Tasks

**Part A: Repository**

1. In **ECR → Private registry → Repositories**, create a repository **`jb-web`** with **Scan on push** enabled.

**Part B: Build and test locally**

2. Build the image for **`linux/amd64`** with `VERSION=v1`, and tag it `jb-web:v1`.
3. Run it locally on port 8081 and open `http://localhost:8081/web/`.

**Part C: Push to ECR**

4. Authenticate Docker to your ECR registry.
5. Tag the image with its full ECR URI and **push** it.
6. In the Console, open the repository. Find the image's **tag**, **digest**, **size** and **scan results**.

**Part D: Run it on Fargate**

7. Create a task definition **`jb-web`** (Fargate, 0.25 vCPU / 0.5 GB, execution role `ecsTaskExecutionRole`), with the image URI `…/jb-web:v1` and container port **80**.
8. Create a target group **`jb-web-tg`** (target type **IP**, HTTP:80, health check `/`), and add an ALB rule: path **`/web*`** → `jb-web-tg`.
9. Create a service **`jb-web-svc`** in `jb-ecs-fargate` with **2 tasks**, security group `jb-fargate-tasks-sg`, public IP on, and load balancing to `jb-web-tg`.
10. Open `http://<alb-dns>/web/`. You should see **version v1**.

**Part E: Roll out version 2**

11. Build `VERSION=v2`, tag it `v2`, and push it.
12. Create a **new revision** of `jb-web` that uses `:v2`, and **update the service** to it.
13. Refresh `/web/` while the deployment runs. What do you see? How does the **Deployments** tab show the change?

**Part F: Lifecycle policy**

14. Add a lifecycle rule to `jb-web`: **keep only the 2 most recent images**.

**Part G: Clean up or continue**

15. Continuing to [jb-lab-5](jb-lab-5.md)? Keep everything. Stopping here? Delete the service, the task definitions, the listener rule, the target group and the repository (with its images), plus the jb-lab-3 resources.

### Questions

- Which IAM role allowed the Fargate task to pull a **private** image? Which policy does it have?
- What's the difference between an image **tag** and an image **digest**? Why might you deploy by digest?
- What would happen if you built the image on an ARM Mac **without** `--platform linux/amd64`?
- During the rollout in Part E, why did you sometimes see v1 and sometimes v2?

---

✅ **Solution:** [jb-lab-4 Solution](jb-lab-4-solution.md)

---

[⬅ jb-lab-3](jb-lab-3.md) | [⬅ Back to 3.06 Containers](README.md) | [jb-lab-5 ➡](jb-lab-5.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
