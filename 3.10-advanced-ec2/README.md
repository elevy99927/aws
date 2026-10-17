# 3.10 Advanced EC2: Load Balancing, Auto Scaling & Route 53

> **Prerequisite:** you already know how to launch an EC2 instance with **user data** that installs Docker and runs a container ([3.3 EC2](../3.3-ec2/README.md)).

## Topics

- [The Elastic Load Balancing (ELB) family – ALB, NLB, GWLB, CLB](#1-elastic-load-balancing-elb)
- [ALB building blocks – listeners, rules, target groups, health checks](#2-alb-building-blocks)
- [Security group chaining – instances accept traffic only from the ALB](#3-security-group-chaining)
- [Auto Scaling – Launch Templates, ASG capacity, health checks, self-healing](#4-ec2-auto-scaling)
- [Scaling policies – target tracking, step, scheduled, predictive](#scaling-policies)
- [Amazon Route 53 – record types, Alias vs. CNAME, public vs. private zones](#5-amazon-route-53)
- [Route 53 routing policies](#routing-policies)
- [Lab architecture and costs](#6-lab-architecture)
- [LAB 1: ALB in front of two instances](#-lab-1-advanced-alb-in-front-of-two-instances)
- [LAB 2: Auto Scaling behind the ALB](#-lab-2-advanced-auto-scaling-behind-the-alb)
- [LAB 3: Route 53 private hosted zone](#-lab-3-advanced-route-53-private-hosted-zone)
- [Terraform](#-terraform)

---

## 1. Elastic Load Balancing (ELB)

**Elastic Load Balancing** is the AWS service family that distributes incoming traffic across multiple targets (EC2 instances, containers, IP addresses, Lambda functions) in **one or more Availability Zones**. A load balancer is managed, highly available and scales automatically.

| Type | OSI layer | Protocols | Typical use |
|------|-----------|-----------|-------------|
| **Application Load Balancer (ALB)** | 7 (application) | HTTP, HTTPS, gRPC, WebSocket | Web apps and APIs. Routes by **path** (`/api/*`), **host** (`api.example.com`), headers and more |
| **Network Load Balancer (NLB)** | 4 (transport) | TCP, UDP, TLS | Extreme performance, millions of requests per second, **static IP** per AZ, non-HTTP traffic |
| **Gateway Load Balancer (GWLB)** | 3 (network) | IP (GENEVE) | Inserting third-party virtual appliances: firewalls, IDS/IPS |
| **Classic Load Balancer (CLB)** | 4 and 7 | HTTP, HTTPS, TCP | **Legacy.** Don't use it for new workloads |

> **Exam tip:** "HTTP routing by path or host" → **ALB**. "Static IP, ultra-low latency, TCP/UDP" → **NLB**. "Third-party firewall appliances" → **GWLB**.

Benefits that come up on the exam:

- **High availability:** traffic is sent only to **healthy** targets, across multiple AZs.
- **Elasticity:** the load balancer scales by itself, and together with Auto Scaling the targets scale too.
- **Single entry point:** clients use one DNS name, while targets come and go behind it.
- **TLS termination:** HTTPS certificates from **AWS Certificate Manager (ACM)** are installed on the load balancer, not on every server.

---

## 2. ALB Building Blocks

```
Client ──► ALB ──► Listener (HTTP:80) ──► Rules ──► Target Group ──► Targets (EC2)
                                                         │
                                                   Health checks
```

| Component | What it does |
|-----------|--------------|
| **Listener** | A process that checks for connections on a **protocol and port**, for example HTTP:80 or HTTPS:443 |
| **Rules** | Decide where a request goes, based on conditions (path, host, header…). Every listener has a **default rule** |
| **Target group** | A group of targets (instances, IPs, Lambda) plus the port and protocol to reach them |
| **Health check** | The ALB requests a path (for example `/`) on every target at a set interval. Targets that fail are marked **unhealthy** and receive **no traffic** |

Target states you will see in the labs:

| State | Meaning |
|-------|---------|
| `initial` | Just registered. The health checks haven't passed yet |
| `healthy` | Passing health checks. Receives traffic |
| `unhealthy` | Failing health checks. No traffic |
| `unused` | Not in use, for example the instance is **stopped** |
| `draining` | Being deregistered. In-flight requests can finish (*deregistration delay*, 300 seconds by default) |

---

## 3. Security Group Chaining

A common best practice is that **only the load balancer** can reach the instances:

| Security group | Inbound rule |
|----------------|--------------|
| `lab-alb-sg` (on the ALB) | HTTP 80 from `0.0.0.0/0` (the internet) |
| `lab-web-sg` (on the instances) | HTTP 80 from **`lab-alb-sg`**, a security group ID and not an IP range |

Even though the instances have public IPs, nobody can reach them directly. All traffic must go through the ALB. When ALB nodes or instances change their IPs, the rule still works, because it references the **group** and not addresses.

---

## 4. EC2 Auto Scaling

**Amazon EC2 Auto Scaling** keeps the right number of instances running: it adds instances when load rises, removes them when load drops, and **replaces unhealthy ones**.

| Component | What it is |
|-----------|------------|
| **Launch Template** | The "recipe" for new instances: AMI, instance type, security groups, IAM instance profile, **user data**. It's versioned |
| **Auto Scaling Group (ASG)** | The group of instances. It has **min / desired / max** capacity and a list of subnets (AZs) |
| **Health check type** | `EC2` (default): replace an instance if EC2 reports it impaired. `ELB`: also replace it if it **fails the load balancer's health check** |
| **Scaling policy** | When and how to change the desired capacity |

```
min = 1        desired = 2        max = 4
 │                  │                  │
never fewer    what the ASG        never more
than this      tries to keep       than this
```

- **Self-healing:** if an instance is terminated or becomes unhealthy, the ASG launches a replacement to get back to *desired*.
- **Multi-AZ:** the ASG spreads instances evenly across the subnets (AZs) you give it.
- The ASG itself is **free**. You pay only for the instances it runs.

### Scaling Policies

| Policy | How it works | Example |
|--------|--------------|---------|
| **Target tracking** (recommended) | You pick a metric and a target value, and AWS adds or removes instances to stay near it, like a thermostat | Average CPU = 50%, or **requests per target = 100/min** |
| **Step scaling** | CloudWatch alarm thresholds with step adjustments | CPU > 70% → +2, CPU > 90% → +4 |
| **Simple scaling** | One alarm → one adjustment, then a cooldown | Legacy. Prefer target tracking or step |
| **Scheduled scaling** | Change capacity at known times | Every weekday at 08:00, desired = 6 |
| **Predictive scaling** | Machine learning forecasts load from history and scales **ahead** of it | Daily traffic patterns |

Target tracking creates **two CloudWatch alarms** for you. **AlarmHigh** scales out quickly, after 3 data points of one minute each. **AlarmLow** scales in slowly, after 15 data points, to avoid flapping.

---

## 5. Amazon Route 53

**Amazon Route 53** is AWS's highly available **DNS** service. It also does **domain registration** and **health checking**. It's a **global** service with a 100% availability SLA.

### Record types

| Record | Points a name to… |
|--------|-------------------|
| `A` / `AAAA` | An IPv4 / IPv6 address |
| `CNAME` | Another name. **Not allowed at the zone apex** (`example.com`) |
| **Alias** (Route 53 specific) | An AWS resource: ALB, CloudFront, S3 website, another record. **Works at the apex**, has **no query charge**, and follows the resource's IP changes automatically |
| `MX` | Mail servers |
| `NS` / `SOA` | The zone's name servers and authority. Created automatically |

> **Exam tip:** to point `example.com` (the apex) at a load balancer, use an **Alias** record. A CNAME isn't allowed there.

### Hosted zones

| | Public hosted zone | Private hosted zone |
|---|---|---|
| Answers queries from | The **internet** | **Only inside the associated VPCs** |
| Requires | A registered domain | Nothing. Any name works, for example `app.internal` |
| Typical use | `www.example.com` → ALB | Internal service names: `db.app.internal`, `api.app.internal` |
| Cost | $0.50/month per zone | $0.50/month per zone (free if deleted within 12 hours) |

### Routing Policies

| Policy | Behavior | Use case |
|--------|----------|----------|
| **Simple** | One answer (can contain several IPs) | A single resource |
| **Weighted** | Splits traffic by percentage | Blue/green deployments, A/B testing (90% / 10%) |
| **Latency** | Answers with the Region that has the lowest latency for the user | Multi-Region apps |
| **Failover** | Primary/secondary, driven by **health checks** | Disaster recovery |
| **Geolocation** | By the user's country or continent | Content localization, compliance |
| **Geoproximity** | By distance, with an adjustable "bias" | Shifting traffic between Regions |
| **Multivalue answer** | Up to 8 healthy records, chosen randomly | Simple client-side load balancing |
| **IP-based** | By the client's IP range (CIDR) | Routing specific ISPs or networks |

---

## 6. Lab Architecture

```
                 Internet
                    │
                    ▼
     ┌─── ALB "lab-alb" (SG: 80 from 0.0.0.0/0) ───┐       Route 53 private zone
     │    Listener HTTP:80 → Target group           │◄───── www.app.internal (Alias)
     └──────────────┬───────────────┬───────────────┘       (resolves only in the VPC)
                    │               │
          us-east-1a│               │us-east-1b
             ┌──────▼─────┐   ┌─────▼──────┐
             │ EC2 (ASG)  │   │ EC2 (ASG)  │   SG: 80 only from the ALB's SG
             │ http-echo  │   │ http-echo  │   docker: hashicorp/http-echo
             └────────────┘   └────────────┘   page: "Container Hostname: ip-172-31-…"
                    Auto Scaling Group: min 1 / desired 2 / max 4
                    Scaling: requests per target = 100/min
```

All labs run in the **default VPC** in **`us-east-1`**.

### 💰 Costs

| Resource | Price (us-east-1) |
|----------|-------------------|
| Application Load Balancer | ~$0.0225/hour + LCU usage |
| EC2 t3.micro | ~$0.0104/hour per instance |
| Public IPv4 address | $0.005/hour each (every instance + one per ALB AZ) |
| Route 53 hosted zone | $0.50/month (free if deleted within 12 hours) |

Everything in these labs running together costs about **$48/month**, which is **~$0.065/hour**. Each lab takes **up to 2 hours**, so it costs about **$0.15**. **Always clean up**: a forgotten ALB and ASG keep billing around the clock.

> 💡 Set up an **AWS Budget** alert (for example $5/month) before you start. See [4.2 Account & Cost Management](../4.2-accounts-and-cost-management/README.md).

---

## 🧪 LAB 1 (Advanced): ALB in Front of Two Instances

> 💰 **Cost alert:** this lab runs an **ALB** and **2 × t3.micro**. Up to 2 hours ≈ **$0.15**. If left running, it costs **≈ $48/month**. Clean up at the end, or continue directly to Lab 2.

**Goal:** Put an Application Load Balancer in front of two web servers, see requests spread across them, and see the ALB route around a failed server.

**Tools:** Console + AWS CLI. Region: `us-east-1`. The user data script is in [`artifacts/user-data.sh`](artifacts/user-data.sh):

```bash
#!/bin/bash
dnf install -y docker
systemctl enable --now docker
docker run -d --restart always --name echo -p 80:5678 \
  hashicorp/http-echo -text="Container Hostname: $HOSTNAME"
```

> `$HOSTNAME` is expanded by the **user data shell on the instance**, so the page shows the **EC2 hostname** (`ip-172-31-…`). The `http-echo` image has no shell. The container listens on port 5678, which is published as port 80 on the instance.

### Tasks

**Part A: Security groups**

1. Create `lab-alb-sg`: inbound **HTTP 80 from `0.0.0.0/0`**.
2. Create `lab-web-sg`: inbound **HTTP 80 from the security group `lab-alb-sg`**. Use the SG as the *source*, not an IP range.

**Part B: Two web servers**

3. Launch two **Amazon Linux 2023** `t3.micro` instances, `lab-web-1` in **us-east-1a** and `lab-web-2` in **us-east-1b**. Use the default VPC, `lab-web-sg`, no key pair, and the user data above.

**Part C: Target group**

4. Create a target group `lab-web-tg`: target type **Instances**, HTTP:80, health check path `/`. Register both instances.

**Part D: Load balancer**

5. Create an **Application Load Balancer** `lab-alb`: internet-facing, IPv4, subnets in **us-east-1a** and **us-east-1b**, security group `lab-alb-sg`, and a listener **HTTP:80 → `lab-web-tg`**.
6. Wait until the ALB is **Active** and both targets are **healthy**.

**Part E: Test**

7. Copy the ALB **DNS name** and open it in a browser. Refresh a few times.
8. From a terminal, send 10 requests with `curl` in a loop and count the hostnames.
9. Try to open an instance's **public IP** directly. What happens, and why?

**Part F: Failure**

10. **Stop** `lab-web-2`. Watch the target group, then send 10 requests again.
11. **Start** `lab-web-2` again and wait until it's healthy.

**Part G: Clean up or continue**

12. Continuing to Lab 2 now? Keep everything. Stopping here? Delete the ALB, the target group, the instances and the security groups (see the solution).

### Questions

- The browser often shows the **same** hostname on every refresh, while `curl` alternates. Why?
- Why does a direct request to the instance's public IP time out, even though port 80 is open in `lab-web-sg`?
- What was the target's state after you stopped the instance? Did any request fail?

---

## 🧪 LAB 2 (Advanced): Auto Scaling Behind the ALB

> 💰 **Cost alert:** this lab runs an **ALB** and **1–4 × t3.micro**. Up to 2 hours ≈ **$0.15**. If left running, it costs **≈ $48/month**. A forgotten ASG **recreates** any instance you terminate, so clean up in the right order.

**Goal:** Replace the hand-made instances with an **Auto Scaling Group**, scale it manually, then let it scale **automatically under load**.

**Prerequisite:** `lab-alb-sg`, `lab-web-sg`, `lab-web-tg` and `lab-alb` from Lab 1. If you deleted them, recreate them with the commands in [Lab 1 Solution](SOLUTION-LAB1.md).

**Tools:** Console + AWS CLI + a load generator: `ab` (ApacheBench, built into macOS, `apache2-utils` on Linux) or [`hey`](https://github.com/rakyll/hey).

### Tasks

**Part A: IAM role for Session Manager** (used in Lab 3)

1. Create an IAM role `lab-ec2-ssm-role` for **EC2** with the AWS managed policy **`AmazonSSMManagedInstanceCore`**, and an instance profile `lab-ec2-ssm-profile`.

**Part B: Launch Template**

2. Create a Launch Template `lab-web-lt`: Amazon Linux 2023, `t3.micro`, `lab-web-sg`, IAM instance profile `lab-ec2-ssm-profile`, and the same user data as Lab 1.

**Part C: Auto Scaling Group**

3. Create an ASG `lab-web-asg` from `lab-web-lt`:
   - Subnets: the default subnets in **us-east-1a** and **us-east-1b**.
   - Attach it to the existing target group **`lab-web-tg`**.
   - Turn on **Elastic Load Balancing health checks**, with a grace period of 90 seconds.
   - Capacity: **min 1, desired 2, max 4**.
4. Wait until two new instances are **healthy** in the target group.
5. **Deregister and terminate** `lab-web-1` and `lab-web-2` from Lab 1. The site should keep working, now served by the ASG.

**Part D: Manual scaling**

6. Change the ASG's **desired capacity to 4**. Watch the **Activity** tab and the target group, then test with `curl`.
7. Change the desired capacity back to **2**.

**Part E: Automatic scaling under load**

8. Add a **target tracking** scaling policy `lab-requests-per-target`: metric **Application Load Balancer request count per target**, target value **100**.
9. Wait a few minutes **without traffic**, then check the Activity tab. What happened to the desired capacity?
10. Generate load against the ALB for about **8 minutes**:
    ```bash
    ab -k -c 10 -t 480 -n 10000000 http://<alb-dns-name>/
    # or: hey -z 8m -c 10 http://<alb-dns-name>/
    ```
11. While the load runs, watch:
    - **CloudWatch → Alarms**: the `TargetTracking-…-AlarmHigh-…` alarm goes **In alarm**.
    - **ASG → Activity**: new instances launch, up to the max of 4.
    - **Target group**: the new targets go from `initial` to `healthy`.
12. Stop the load and wait about 15 minutes. The ASG **scales in** again.

**Part F: Clean up or continue**

13. Continuing to Lab 3 now? Keep everything. Stopping here? Follow the cleanup in the [Lab 3 Solution](SOLUTION-LAB3.md#part-f-clean-up), which covers everything.

### Questions

- Why did the ASG scale in to **1** instance before you started the load?
- Why does scale-out happen within a few minutes, while scale-in takes about 15?
- `ab` reports thousands of *Failed requests*, yet all responses were `200`. Why?
- If you terminate an ASG instance manually, what happens? Why is that useful, and why is it dangerous when cleaning up?

---

## 🧪 LAB 3 (Advanced): Route 53 Private Hosted Zone

> 💰 **Cost alert:** this lab keeps the **ALB** and **ASG** from Lab 2 running and adds a **hosted zone**. Up to 2 hours ≈ **$0.15**. The hosted zone is free if you delete it within 12 hours, otherwise it costs $0.50. Clean up **everything** at the end.

**Goal:** Give the load balancer a friendly **internal** name, `www.app.internal`, that works only inside the VPC.

**Prerequisite:** the ALB and the ASG from Lab 2, including the SSM instance profile.

### Tasks

**Part A: Private hosted zone**

1. In **Route 53 → Hosted zones**, create a **private** hosted zone `app.internal`, associated with the **default VPC** in **us-east-1**.

**Part B: Alias record**

2. In the zone, create a record **`www`**, type **A**, **Alias** on, pointing to **Application Load Balancer → us-east-1 → `lab-alb`**.

**Part C: Test from outside the VPC**

3. From your laptop, run `nslookup www.app.internal`. What's the result?

**Part D: Test from inside the VPC**

4. Open **EC2 → Instances**, select one of the `lab-asg-web` instances, choose **Connect → Session Manager → Connect**. You get a shell in the browser with no SSH key and no open port 22.
5. In the session, run:
   ```bash
   getent hosts www.app.internal
   for i in 1 2 3 4 5 6; do curl -s http://www.app.internal; done
   ```

**Part E: Theory (with a public domain)**

6. In a **public** hosted zone for a domain you own, the same Alias record (`www.example.com` → ALB) would work from anywhere on the internet. Which **routing policy** would you use to send 10% of users to a new version of the app running behind a second ALB?

**Part F: Clean up everything**

7. Delete all resources from Labs 1–3 **in this order**: the Route 53 record and zone, the **ASG**, the ALB, the target group, the Launch Template, the security groups, and finally the IAM role and instance profile.

### Questions

- Why does `www.app.internal` resolve inside the VPC but not from your laptop?
- Why use an **Alias** record and not a **CNAME** to point to the ALB?
- How did you get a shell on the instance without an SSH key or an open port 22?

---

## 🏗️ Terraform

> Terraform is covered later in the course. The code is here **for reference**, so you can compare it with what you built by hand.

The [`terraform/`](terraform/) folder builds the **final state of all three labs**: security groups, ALB, target group, listener, IAM role, Launch Template, ASG, the target tracking policy, and the private hosted zone with the Alias record. It doesn't include the two manual instances from Lab 1, because the ASG replaces them.

```bash
cd terraform
terraform init
terraform apply      # ~3 minutes, prints the ALB URL
terraform destroy    # ~6 minutes, removes all 13 resources
```

---

## ✅ Solutions

- **[Lab 1 Solution](SOLUTION-LAB1.md)**: security groups, instances, target group, ALB, testing and failover
- **[Lab 2 Solution](SOLUTION-LAB2.md)**: IAM role, Launch Template, ASG, manual and automatic scaling
- **[Lab 3 Solution](SOLUTION-LAB3.md)**: private hosted zone, Alias record, Session Manager test, full cleanup

---

[⬅ Previous: 3.9 Monitoring & Auditing](../3.9-monitoring/README.md) | [🏠 Home](../README.md) | [Next: 4.1 EC2 Pricing Models ➡](../4.1-ec2-pricing-models/README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
