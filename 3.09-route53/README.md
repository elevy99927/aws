# 3.09 Amazon Route 53

> **Prerequisite:** the ALB and the Auto Scaling group from [3.08 Load Balancing & Auto Scaling](../3.08-load-balancing-auto-scaling/README.md), Lab 2.

## Topics

- [What is Route 53 – DNS, domain registration and health checking](#1-amazon-route-53)
- [Record types, and Alias vs. CNAME](#record-types)
- [Public vs. private hosted zones](#hosted-zones)
- [Routing policies – Simple, Weighted, Latency, Failover, Geolocation, Geoproximity, Multivalue, IP-based](#routing-policies)
- [LAB 1: Route 53 private hosted zone](#-lab-1-advanced-route-53-private-hosted-zone)
- Coming soon: health checks and failover routing, domain registration, Route 53 Resolver (hybrid DNS)

---

## 1. Amazon Route 53

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

## 🧪 LAB 1 (Advanced): Route 53 Private Hosted Zone

> 💰 **Cost alert:** this lab keeps the **ALB** and **ASG** from 3.08 Lab 2 running and adds a **hosted zone**. Up to 2 hours ≈ **$0.15**. The hosted zone is free if you delete it within 12 hours, otherwise it costs $0.50. Clean up **everything** at the end.

**Goal:** Give the load balancer a friendly **internal** name, `www.app.internal`, that works only inside the VPC.

**Prerequisite:** the ALB and the ASG from [3.08 Lab 2](../3.08-load-balancing-auto-scaling/README.md), including the SSM instance profile.

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

7. Delete all resources from 3.08 Labs 1–2 and from this lab **in this order**: the Route 53 record and zone, the **ASG**, the ALB, the target group, the Launch Template, the security groups, and finally the IAM role and instance profile.

### Questions

- Why does `www.app.internal` resolve inside the VPC but not from your laptop?
- Why use an **Alias** record and not a **CNAME** to point to the ALB?
- How did you get a shell on the instance without an SSH key or an open port 22?

---

## Solutions

- **[Lab 1 Solution](SOLUTION-LAB1.md)**: private hosted zone, Alias record, Session Manager test, full cleanup

---

[⬅ Previous: 3.08 Load Balancing & Auto Scaling](../3.08-load-balancing-auto-scaling/README.md) | [🏠 Home](../README.md) | [Next: 3.10 CloudFront & API Gateway ➡](../3.10-cloudfront-api-gateway/README.md)

---

## Terraform Code

The Terraform code for this lab is part of [3.08's `terraform/`](../3.08-load-balancing-auto-scaling/terraform/) folder, which builds the 3.08 labs together with this private hosted zone and its Alias record.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
