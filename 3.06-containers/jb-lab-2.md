# 3.06 Containers – Lab 2: ECS Service Load Balancing

[⬅ Lab 1](jb-lab-1.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 3 ➡](jb-lab-3.md)

> 📚 Based on the course slides *ECS – Connecting everything*: service load balancing, ALB features, ground rules, dynamic port forwarding, and the follow-through *Connecting ALB*.

---

## 1. Load Balancers for ECS Services

An ECS **service** can register its tasks with a load balancer automatically. When a task starts, ECS adds it to the **target group**. When it stops, ECS removes it.

| Load balancer | Layer | Use with ECS |
|---------------|-------|--------------|
| **Application Load Balancer (ALB)** | 7: HTTP/HTTPS | **The recommended choice** for web services. Supports everything below |
| **Network Load Balancer (NLB)** | 4: TCP/UDP | Non-HTTP traffic, a static IP, extreme performance |
| **Classic Load Balancer (CLB)** | 4/7 | **Legacy.** EC2 launch type only, not Fargate. Don't use it for new services |

Load balancers in general are covered in [3.08 Load Balancing & Auto Scaling](../3.08-load-balancing-auto-scaling/README.md).

## 2. Why the ALB Fits ECS

From the slides, still true today:

- **Dynamic host port mapping:** many tasks of the same service can run on **one** instance.
- **Path-based (and host-based) routing:** several services share **one** ALB and **one** listener port, for example `/admin` → admin service and `/store` → store service.
- **Several target groups per service**, to expose more than one port.
- Works with both the **EC2** and **Fargate** launch types.
- Supports **slow start**: a new task receives traffic gradually.

## 3. Dynamic Host Port Mapping

In [Lab 1](jb-lab-1.md), `hostPort: 8080` allowed only **one** task per instance. With a load balancer, set **no host port** (`hostPort: 0`). Docker then picks a **random free host port** (an ephemeral port, typically from 32768 to 65535) for each task. ECS registers *instance + port* in the target group, so the ALB knows where each task is.

![Dynamic host port mapping: a browser sends requests to the ALB ecs-alb, whose HTTP:80 listener routes /admin* to the target group admin-tg and /store* to store-tg. Two EC2 instances in us-east-1a and us-east-1b each run one admin task and one store task, and each task maps its own random host port (for example 32789) to container port 80. The target groups list each instance with its task's port, and the instances' security group ecs-instances-sg allows ports 32768-65535 only from ecs-alb-sg](images/jb-lab-2.jpg)

<sub>Diagram source: [images/jb-lab-2.drawio](images/jb-lab-2.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

> 🔐 Because the host ports are random, the **instances' security group** must allow the ephemeral port range **from the ALB's security group**, not from the internet.

## 4. Ground Rules

| Rule | Details |
|------|---------|
| **Up to 5 target groups per service** | Each one can expose a different container port |
| **HTTP + HTTPS** | Use two listeners: **443** forwards to the service, and **80** redirects to 443 |
| **Subnets** | The load balancer's subnets must cover **every AZ** where your tasks run |
| **Health checks** | A task that fails the target group's health check is **stopped and replaced** until the service reaches its desired count |
| **Task definition updates** | The container name and port that the service's load balancer uses must stay in the new task definition revision |
| **Changing the load balancer** | The slides say this is immutable. That was true in 2020, but **today you can update the load balancer configuration of an existing service** |

---

## 🧪 Lab 2 (Basic): Two Services Behind One ALB

> 💰 **Cost:** the ALB plus 2 × t3.small from Lab 1, about **$0.08/hour**. Up to 2 hours ≈ **$0.16**. If left running ≈ **$58/month**.

**Goal:** Run two services, `admin` and `store`, on the Lab 1 cluster with **dynamic host ports**. Put **one ALB** in front of them that routes by **path**, and see several tasks share one instance.

**Prerequisite:** the cluster `ecs-ec2` and the security group `ecs-instances-sg` from [Lab 1](jb-lab-1.md).

**Tools:** Console + AWS CLI. Region: `us-east-1`. The image `traefik/whoami` prints a `Name:` line from the environment variable `WHOAMI_NAME`, which shows which service answered.

### Tasks

**Part A: Prepare**

1. Delete the service `whoami-svc` from Lab 1 (or set its desired tasks to 0).
2. Create a security group **`ecs-alb-sg`** that allows **HTTP 80 from anywhere**.
3. In **`ecs-instances-sg`**, add an inbound rule: **TCP 32768–65535 from `ecs-alb-sg`**.

**Part B: Task definitions with dynamic ports**

4. Create two task definitions, **`admin`** and **`store`**. Use EC2, network mode **bridge**, 0.25 vCPU and 0.5 GB:
   - Image `traefik/whoami`, container port **80**, and **no host port** (leave it empty).
   - Environment variable `WHOAMI_NAME` = `admin` or `store`.

**Part C: Load balancer**

5. Create two target groups, **`admin-tg`** and **`store-tg`**: target type **Instances**, HTTP:80, health check path `/`. **Don't register any targets.** ECS will.
6. Create an ALB **`ecs-alb`**: internet-facing, all default subnets, security group `ecs-alb-sg`. Set the listener **HTTP:80** with a **default action that returns a fixed 404** with the text `no route`.
7. Add two listener rules: path **`/admin*`** → `admin-tg`, and path **`/store*`** → `store-tg`.

**Part D: Services**

8. Create the services **`admin-svc`** (from `admin`) and **`store-svc`** (from `store`), each with **2 tasks**. Under **Load balancing**, choose the existing `ecs-alb` and the matching target group.

**Part E: Test**

9. Call `http://<alb-dns>/admin` and `http://<alb-dns>/store` several times. What do the `Name:` and `Hostname:` lines show?
10. Call `http://<alb-dns>/`. What do you get, and why?
11. Open `admin-tg` → **Targets**. Which **ports** are registered? Are there two tasks on the **same** instance?

**Part F: Clean up or continue**

12. Continuing to [Lab 3](jb-lab-3.md)? Delete the services, the task definitions' revisions and the cluster `ecs-ec2`, but **keep the ALB `ecs-alb` and `ecs-alb-sg`**. Stopping here? Delete everything, including the ALB, the target groups and both security groups.

### Questions

- Why does the instances' security group allow ports 32768–65535 only from the ALB's security group?
- How does the ALB know which port each task listens on?
- What would you change to serve both services over HTTPS?
- What happens to a task that fails its health check?

---

✅ **Solution:** [Lab 2 Solution](jb-lab-2-solution.md)

---

[⬅ Lab 1](jb-lab-1.md) | [⬅ Back to 3.06 Containers](README.md) | [Lab 3 ➡](jb-lab-3.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
