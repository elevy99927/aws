# 3.06 Containers – jb-lab-2: ECS Service Load Balancing

[⬅ jb-lab-1](jb-lab-1.md) | [⬅ Back to 3.06 Containers](README.md) | [jb-lab-3 ➡](jb-lab-3.md)

> 📚 Based on the course slides *ECS – Connecting everything*: service load balancing, ALB features, ground rules, dynamic port forwarding, and the follow-through *Connecting ALB*.

---

## 1. Load Balancers for ECS Services

An ECS **service** can register its tasks with a load balancer automatically. When a task starts, ECS adds it to the **target group**. When it stops, ECS removes it.

| Load balancer | Layer | Use with ECS |
|---------------|-------|--------------|
| **Application Load Balancer (ALB)** | 7: HTTP/HTTPS | **The recommended choice** for web services. Supports everything below |
| **Network Load Balancer (NLB)** | 4: TCP/UDP | Non-HTTP traffic, a static IP, extreme performance |
| **Classic Load Balancer (CLB)** | 4/7 | **Legacy.** EC2 launch type only, not Fargate. Don't use it for new services |

Load balancers in general are covered in [3.10 Advanced EC2](../3.10-advanced-ec2/README.md).

## 2. Why the ALB Fits ECS

From the slides, still true today:

- **Dynamic host port mapping:** many tasks of the same service can run on **one** instance.
- **Path-based (and host-based) routing:** several services share **one** ALB and **one** listener port, for example `/admin` → admin service and `/store` → store service.
- **Several target groups per service**, to expose more than one port.
- Works with both the **EC2** and **Fargate** launch types.
- Supports **slow start**: a new task receives traffic gradually.

## 3. Dynamic Host Port Mapping

In [jb-lab-1](jb-lab-1.md), `hostPort: 8080` allowed only **one** task per instance. With a load balancer, set **no host port** (`hostPort: 0`). Docker then picks a **random free host port** (an ephemeral port, typically from 32768 to 65535) for each task. ECS registers *instance + port* in the target group, so the ALB knows where each task is.

```
                                          ┌──────── EC2 instance A ─────────┐
                     /admin/*  ──────────►│  :32689 → admin task :80        │
                                          │  :32657 → store task :80        │
  www ──► Application Load Balancer       └─────────────────────────────────┘
          (one listener, port 80)         ┌──────── EC2 instance B ─────────┐
                     /store/*  ──────────►│  :32667 → admin task :80        │
                                          │  :32713 → store task :80        │
                                          └─────────────────────────────────┘
                    random host ports per task  →  "dynamic port forwarding"
```

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

## 🧪 jb-lab-2 (Basic): Two Services Behind One ALB

> 💰 **Cost:** the ALB plus 2 × t3.small from jb-lab-1, about **$0.08/hour**. Up to 2 hours ≈ **$0.16**. If left running ≈ **$58/month**.

**Goal:** Run two services, `admin` and `store`, on the jb-lab-1 cluster with **dynamic host ports**. Put **one ALB** in front of them that routes by **path**, and see several tasks share one instance.

**Prerequisite:** the cluster `jb-ecs-ec2` and the security group `jb-ecs-instances-sg` from [jb-lab-1](jb-lab-1.md).

**Tools:** Console + AWS CLI. Region: `us-east-1`. The image `traefik/whoami` prints a `Name:` line from the environment variable `WHOAMI_NAME`, which shows which service answered.

> 🏫 **Classroom account rules:** work only in **`us-east-1`**, and name your resources with the **`jb-`** prefix.

### Tasks

**Part A: Prepare**

1. Delete the service `whoami-svc` from jb-lab-1 (or set its desired tasks to 0).
2. Create a security group **`jb-ecs-alb-sg`** that allows **HTTP 80 from anywhere**.
3. In **`jb-ecs-instances-sg`**, add an inbound rule: **TCP 32768–65535 from `jb-ecs-alb-sg`**.

**Part B: Task definitions with dynamic ports**

4. Create two task definitions, **`jb-admin`** and **`jb-store`**. Use EC2, network mode **bridge**, 0.25 vCPU and 0.5 GB:
   - Image `traefik/whoami`, container port **80**, and **no host port** (leave it empty).
   - Environment variable `WHOAMI_NAME` = `admin` or `store`.

**Part C: Load balancer**

5. Create two target groups, **`jb-admin-tg`** and **`jb-store-tg`**: target type **Instances**, HTTP:80, health check path `/`. **Don't register any targets.** ECS will.
6. Create an ALB **`jb-ecs-alb`**: internet-facing, all default subnets, security group `jb-ecs-alb-sg`. Set the listener **HTTP:80** with a **default action that returns a fixed 404** with the text `no route`.
7. Add two listener rules: path **`/admin*`** → `jb-admin-tg`, and path **`/store*`** → `jb-store-tg`.

**Part D: Services**

8. Create the services **`admin-svc`** (from `jb-admin`) and **`store-svc`** (from `jb-store`), each with **2 tasks**. Under **Load balancing**, choose the existing `jb-ecs-alb` and the matching target group.

**Part E: Test**

9. Call `http://<alb-dns>/admin` and `http://<alb-dns>/store` several times. What do the `Name:` and `Hostname:` lines show?
10. Call `http://<alb-dns>/`. What do you get, and why?
11. Open `jb-admin-tg` → **Targets**. Which **ports** are registered? Are there two tasks on the **same** instance?

**Part F: Clean up or continue**

12. Continuing to [jb-lab-3](jb-lab-3.md)? Delete the services, the task definitions' revisions and the cluster `jb-ecs-ec2`, but **keep the ALB `jb-ecs-alb` and `jb-ecs-alb-sg`**. Stopping here? Delete everything, including the ALB, the target groups and both security groups.

### Questions

- Why does the instances' security group allow ports 32768–65535 only from the ALB's security group?
- How does the ALB know which port each task listens on?
- What would you change to serve both services over HTTPS?
- What happens to a task that fails its health check?

---

✅ **Solution:** [jb-lab-2 Solution](jb-lab-2-solution.md)

---

[⬅ jb-lab-1](jb-lab-1.md) | [⬅ Back to 3.06 Containers](README.md) | [jb-lab-3 ➡](jb-lab-3.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
