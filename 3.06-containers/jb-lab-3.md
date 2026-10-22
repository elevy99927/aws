# 3.06 Containers – Lab 3: AWS Fargate

[⬅ Lab 2](jb-lab-2.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 4 ➡](jb-lab-4.md)

> 📚 Based on the course slides *Fargate – The almighty*: what Fargate is, ECS with EC2 vs. ECS with Fargate, and the follow-through *Building a new cluster using Fargate*.

---

## 1. What is AWS Fargate?

**AWS Fargate** is a **serverless compute engine for containers**. It works with **Amazon ECS** and **Amazon EKS**. You describe the task (image, CPU, memory, network), and AWS runs it, with **no EC2 instances** to create, patch or scale.

## 2. ECS with EC2 vs. ECS with Fargate

| | **ECS on EC2** ([Lab 1](jb-lab-1.md)) | **ECS on Fargate** |
|---|---|---|
| Servers | **You** create the EC2 instances (an Auto Scaling Group) | **None.** No instances in your account |
| Patching the OS and the ECS agent | **You** | AWS |
| Scaling | Add tasks **and** make sure there are enough instances for them | Just increase the **number of tasks** |
| Capacity planning | Instance types, bin packing, free ports | None. Each task gets exactly the CPU and memory it asks for |
| Network mode | `bridge`, `host` or `awsvpc` | **`awsvpc` only**: every task gets its own network interface (ENI) and private IP |
| Load balancer target type | `instance` (with dynamic ports) | **`ip`** (the task's own IP) |
| GPU, custom AMI, SSH into the host | ✅ | ❌ |
| Billing | Per instance, even when it's half empty | Per task: **vCPU-hours + GB-hours**, per second |

> Between the two there's a third option, **ECS Managed Instances**: EC2 instances that ECS launches, patches and scales for you, for workloads that need instance-level choices (such as GPUs) without the maintenance.

## 3. Fargate Essentials

| Topic | Details |
|-------|---------|
| **Task size** | You choose CPU and memory from fixed combinations, from **0.25 vCPU / 0.5 GB** up to **16 vCPU / 120 GB** |
| **Platform** | Linux on **x86_64** or **ARM64** (Graviton, cheaper), or Windows |
| **Networking** | `awsvpc`: each task has its own ENI, private IP and **security group**. To pull images from the internet, a task in a public subnet needs a **public IP**, and one in a private subnet needs a **NAT gateway** or VPC endpoints |
| **Storage** | 20 GB of ephemeral storage by default, up to 200 GB |
| **Fargate Spot** | Up to 70% cheaper, but tasks can be interrupted with a 2-minute warning. Good for fault-tolerant work |
| **Price** (us-east-1, Linux x86) | About **$0.04048 per vCPU-hour** and **$0.004445 per GB-hour**. A 0.25 vCPU / 0.5 GB task costs about **$0.0123/hour** |

---

## 🧪 Lab 3 (Basic): The Same Service, Without Servers

> 💰 **Cost:** the ALB (about $0.0225/hour) plus 2–4 Fargate tasks (about $0.0123/hour each, plus a public IP at $0.005/hour each). Up to 2 hours ≈ **$0.15**. If left running ≈ **$45/month**.

**Goal:** Build a **Fargate-only** cluster and run the `whoami` service behind the ALB from Lab 2, then scale it, without creating a single instance.

**Prerequisite:** the ALB `ecs-alb` and the security group `ecs-alb-sg` from [Lab 2](jb-lab-2.md). If you deleted them, create them again as in Lab 2, Parts A and C.

**Tools:** Console + AWS CLI. Region: `us-east-1`.

### Tasks

**Part A: A Fargate-only cluster**

1. Create a cluster **`ecs-fargate`** with infrastructure **Fargate only**.

**Part B: A Fargate task definition**

2. Create a task definition **`whoami-fargate`**:
   - Launch type **AWS Fargate**, OS **Linux/X86_64**, CPU **0.25 vCPU**, memory **0.5 GB**. The network mode is `awsvpc` and can't be changed.
   - Task execution role: **`ecsTaskExecutionRole`**. The Console creates it if it doesn't exist.
   - Container `whoami`, image `traefik/whoami`, container port **80**, environment variable `WHOAMI_NAME` = `fargate`.

**Part C: Networking for the tasks**

3. Create a security group **`fargate-tasks-sg`** that allows **TCP 80 from `ecs-alb-sg`** only.
4. Create a target group **`fargate-tg`** with target type **IP addresses**, HTTP:80, health check path `/`. Don't register targets.
5. On the ALB's HTTP:80 listener, add a rule: path **`/fargate*`** → `fargate-tg`.

**Part D: Service**

6. Create a service **`whoami-fargate-svc`** in `ecs-fargate`: launch type **Fargate**, **2 tasks**, the default VPC's subnets, security group `fargate-tasks-sg`, **public IP on**, and load balancing to `ecs-alb` → `fargate-tg`.

**Part E: Test and explore**

7. Call `http://<alb-dns>/fargate` several times. What do `Name:`, `Hostname:` and `IP:` show?
8. Open `fargate-tg` → **Targets**. What's registered: instances or IPs?
9. Open the cluster's **Infrastructure** tab. How many container instances are there?
10. In **EC2 → Network interfaces**, find the interfaces that belong to your tasks.

**Part F: Scale without servers**

11. Update the service to **4 tasks**. How long until all 4 are *Running* and healthy? Did you have to add any capacity?
12. **Stop** one task and watch the service replace it. Then set the desired tasks back to **2**.

**Part G: Clean up or continue**

13. Continuing to [Lab 4](jb-lab-4.md)? Keep everything. Stopping here? Delete the service, the cluster, the listener rule, the target group, the ALB and the security groups.

### Questions

- Why does a Fargate task need its own security group, while in Lab 1 the security group belonged to the instance?
- Why does `fargate-tg` use the target type **IP** and not **Instance**?
- In the slides: "Scaling? Just increase the task number. No more EC2!" What did you **not** have to do in Part F that you would have had to do with EC2?
- Why does each task need a public IP in this lab? What would you use in a private subnet?

---

✅ **Solution:** [Lab 3 Solution](jb-lab-3-solution.md)

---

[⬅ Lab 2](jb-lab-2.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 4 ➡](jb-lab-4.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
