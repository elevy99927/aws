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

## 🧪 Lab 3 (Basic): Your First Fargate Service

> 💰 **Cost:** each task (0.25 vCPU / 0.5 GB) costs about **$0.0123/hour**, plus **$0.005/hour** for its public IPv4 address. Two tasks for an hour ≈ **$0.04**. If left running ≈ **$25/month**, so clean up at the end.

**Goal:** Run the `whoami` container on a **Fargate-only** cluster, open it in your browser, then scale it and replace a task, without creating a single server.

**Prerequisite:** the [Networking lab](../2.04-vpc-and-networking/lab-1.md): the VPC **`ecs-vpc`** with the public subnets `ecs-public-1a` and `ecs-public-1b`. You don't need a load balancer: you open each task directly through its public IP.

**Tools:** Console + AWS CLI. Region: `us-east-1`.

### Tasks

**Part A: A Fargate-only cluster**

1. Create a cluster **`ecs-fargate`** with infrastructure **Fargate only**.

**Part B: A Fargate task definition**

2. Create a task definition **`whoami-fargate`**:
   - Launch type **AWS Fargate**, OS **Linux/X86_64**, CPU **.25 vCPU**, memory **.5 GB**. The network mode is `awsvpc` and can't be changed.
   - Task execution role: **`ecsTaskExecutionRole`**. The Console creates it if it doesn't exist.
   - Container `whoami`, image `traefik/whoami`, container port **80**, environment variable `WHOAMI_NAME` = `fargate`.

**Part C: A security group for the tasks**

3. In **`ecs-vpc`**, create a security group **`fargate-tasks-sg`** that allows **HTTP (80) from My IP** only.

**Part D: Service**

4. Create a service **`whoami-fargate-svc`** in `ecs-fargate`: **2 tasks** of `whoami-fargate`, the VPC **`ecs-vpc`** and both of its subnets, security group **`fargate-tasks-sg`** only (remove the default one), **public IP on**, no load balancer.

**Part E: Test and explore**

5. Open a task and find its **private IP** and **public IP**. Open `http://<public-ip>` in your browser. What do `Name:`, `Hostname:` and `IP:` show?
6. Open the cluster's **Infrastructure** tab. How many container instances are there?
7. In **EC2 → Network interfaces**, find the interfaces that belong to your tasks. Who created them?

**Part F: Scale without servers**

8. Update the service to **4 tasks**. How long until all 4 are *Running*? Did you have to add any capacity?
9. **Stop** one task and watch the service replace it. Then set the desired tasks back to **2**.

**Part G: Clean up**

10. Delete the service, the cluster and the security group `fargate-tasks-sg`, and deregister the task definition. Keep **`ecs-vpc`** and **`ecsTaskExecutionRole`**: the next labs use them.

### Questions

- Why does a Fargate task need its own security group, while in Lab 1 the security group belonged to the instance?
- Why does each task need a **public IP** in this lab? What would you use in a private subnet?
- In the slides: "Scaling? Just increase the task number. No more EC2!" What did you **not** have to do in Part F that you would have had to do with EC2?
- Each task has its own public IP, and a replacement task gets a new one. Why is that a problem for real users, and what would you put in front of the service?

---

✅ **Solution:** [Lab 3 Solution](jb-lab-3-solution.md)

---

[⬅ Lab 2](jb-lab-2.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 4 ➡](jb-lab-4.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
