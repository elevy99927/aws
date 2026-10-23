# 3.06 Containers – Lab 5: ECS Service Auto Scaling

[⬅ Lab 4](jb-lab-4.md) | [⬅ Back to 3.06 Containers](README.md)

> 📚 ECS Auto Scaling appears on the agenda of the course slides (*ECS clusters – getting things done with almighty ECS*). This page covers it hands-on.

---

## 1. Two Layers of Scaling

With ECS, "scaling" can mean two different things:

| Layer | What scales | Who scales it | Needed on Fargate? |
|-------|-------------|---------------|--------------------|
| **Service auto scaling** | The **number of tasks** in a service (its desired count) | **Application Auto Scaling** policies | ✅ **This lab** |
| **Cluster capacity** | The **EC2 instances** that tasks run on | A **capacity provider** with *managed scaling* adjusts the Auto Scaling Group | ❌ Fargate has no instances, so there's nothing to scale |

On EC2 you usually need **both**: more tasks, and enough instances to place them. On Fargate, only the first. That's the "no more EC2" promise from the slides.

## 2. Service Auto Scaling Policies

You register the service as a **scalable target** with a **minimum** and **maximum** number of tasks, then attach one or more policies:

| Policy | How it works | Example |
|--------|--------------|---------|
| **Target tracking** (recommended) | Keeps a metric near a target value, like a thermostat | Average CPU = 50%, or **ALB requests per target = 100** |
| **Step scaling** | CloudWatch alarm thresholds with step adjustments | CPU > 70% → +2 tasks |
| **Scheduled scaling** | Changes min/max at set times | Every weekday at 08:00, min = 4 |
| **Predictive scaling** | Forecasts load from history and scales ahead of it | Daily traffic patterns |

Predefined metrics for target tracking:

| Metric | Measures |
|--------|----------|
| `ECSServiceAverageCPUUtilization` | Average CPU of the service's tasks |
| `ECSServiceAverageMemoryUtilization` | Average memory of the service's tasks |
| `ALBRequestCountPerTarget` | Requests per minute per task, from the ALB target group |

Target tracking creates two CloudWatch alarms. **AlarmHigh** scales out after about 3 minutes above the target. **AlarmLow** scales in after about 15 minutes below it, slowly on purpose, to avoid flapping. This is the same mechanism as the EC2 Auto Scaling Group in [3.08 Load Balancing & Auto Scaling](../3.08-load-balancing-auto-scaling/README.md).

> **Why requests and not CPU here?** The `web` container serves a static page, so it barely uses CPU, and a CPU target would hardly react. `ALBRequestCountPerTarget` measures exactly the load that the ALB sends to each task.

---

## 🧪 Lab 5 (Basic): Scale the Service Under Load

> 💰 **Cost:** the ALB plus 1–4 Fargate tasks, about **$0.03–$0.09/hour**. Up to 2 hours ≈ **$0.15**. At the end of this lab, delete **everything** from Lab 1 to Lab 5.

**Goal:** Let ECS scale `web-svc` automatically, out under load and back in when the load stops.

**Prerequisite:** the service `web-svc` behind `ecs-alb` from [Lab 4](jb-lab-4.md).

**Tools:** Console + AWS CLI + a load generator: `ab` (ApacheBench, built into macOS, `apache2-utils` on Linux) or `hey`.

> Work in **`us-east-1`**.

### Tasks

**Part A: Scalable target and policy**

1. In `web-svc` → **Update service → Service auto scaling**, set **minimum 1**, **desired 2**, **maximum 4** tasks.
2. Add a **target tracking** policy **`web-requests`**: metric **ALBRequestCountPerTarget**, target group `web-tg`, target value **100**.
3. In **CloudWatch → Alarms**, find the two alarms that the policy created.

**Part B: Scale in without traffic**

4. Wait without sending traffic, then check the service's desired count and **Events**. What happened, and why?

**Part C: Scale out under load**

5. Send load to the service for about **8 minutes**:
   ```bash
   ab -k -c 10 -t 480 -n 10000000 http://<alb-dns>/web/
   ```
6. While it runs, watch:
   - **CloudWatch → Alarms**: `…AlarmHigh…` goes **In alarm**.
   - **The service → Events / Tasks**: new tasks start, up to **4**.
   - **`web-tg` → Targets**: new IPs go from `initial` to `healthy`.

**Part D: Scale in after the load**

7. Stop the load and wait about 15 minutes. How many tasks are running now?

**Part E: Clean up the whole chapter**

8. Delete, in this order:
   - the services `web-svc`, `whoami-fargate-svc` and any services left in `ecs-ec2` (which also removes the scaling policy and its alarms),
   - the clusters `ecs-fargate` and `ecs-ec2`,
   - the ALB `ecs-alb`, then its target groups,
   - the security groups `fargate-tasks-sg`, `ecs-instances-sg` and `ecs-alb-sg`,
   - the ECR repository `web` (with its images),
   - the task definition revisions (deregister, then delete).

### Questions

- What's the difference between **service auto scaling** and **cluster capacity scaling**? Which one did Fargate make unnecessary?
- Why did the service scale **in** to 1 task before the load started?
- Why is scale-out fast and scale-in slow?
- Which metric would you choose for a CPU-heavy service, such as image processing?

---

✅ **Solution:** [Lab 5 Solution](jb-lab-5-solution.md)

---

[⬅ Lab 4](jb-lab-4.md) | [⬅ Back to 3.06 Containers](README.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
