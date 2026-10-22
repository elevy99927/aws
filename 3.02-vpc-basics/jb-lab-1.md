# 3.02 VPC and Networking – Lab 1: Build a VPC with Public Subnets

[⬅ Back to 3.02 VPC and Networking](README.md) | [Next: Containers – Lab 1 ➡](../3.06-containers/jb-lab-1.md) | [Advanced Networking ➡](../3.08-advanced-vpc/README.md)

**▶ Video walkthrough** (6 min):

[![Video: 3.02 Lab 1 – Build a VPC with Public Subnets](https://img.youtube.com/vi/SleiMAS1Tb4/maxresdefault.jpg)](https://youtu.be/SleiMAS1Tb4)

In this lab you build a small network in AWS by hand, one piece at a time: a **VPC**, two **public subnets** in two **Availability Zones**, an **internet gateway** and a **route table**. The labs that follow run in this network, starting with the [Containers labs](../3.06-containers/jb-lab-1.md).

**Why build it yourself?** AWS creates a *default VPC* in every Region of a new account, and it's ready to use. Building your own shows what each piece does and why it's there, and it gives the next labs a network you know exactly.

Region: **`us-east-1`** (N. Virginia). The lab has **five steps**: four to build the network, and one to check it.

```
 1. VPC  ──►  2. Subnets  ──►  3. Internet gateway  ──►  4. Route table  ──►  5. Check
 ecs-vpc      ecs-public-1a    ecs-igw                   ecs-public-rt            resource map
              ecs-public-1b                              0.0.0.0/0 → ecs-igw
```

> 💰 **Cost:** the VPC, subnets, internet gateway and route tables have **no hourly charge**. You pay for what runs in and through the network: EC2 instances, load balancers, data transfer, and **public IPv4 addresses**, which are billed per hour while they're assigned. A NAT gateway would also cost money, but this lab doesn't use one.

---

## 1. VPC

**What is a VPC?** A Virtual Private Cloud is your own isolated network in one AWS Region. You choose its IP address range (a **CIDR block**), and everything you launch in it (instances, load balancers, databases) gets an address from that range.

**Why `10.0.0.0/16`?**
- Addresses that start with `10.` are a **private range** (RFC 1918). They're never used on the internet, so they can't clash with public addresses.
- `/16` fixes the first 16 bits (`10.0`) and leaves **65,536 addresses**: plenty of room to split into many subnets.
- Choose a range that won't overlap with networks you may connect later (another VPC, an office VPN). Address planning is covered in depth in [Advanced Networking](../3.08-advanced-vpc/README.md).

1. Open **VPC → Your VPCs** and choose **Create VPC**. If your account has a default VPC, you see it in the list.

   ![Your VPCs – Create VPC](images/lab1-01-your-vpcs.jpg)

2. Resources to create: **VPC only**. Name tag: **`ecs-vpc`**. IPv4 CIDR: **`10.0.0.0/16`**. Leave *No IPv6 CIDR block* and Tenancy *Default*.

   ![Create VPC – VPC only, ecs-vpc, 10.0.0.0/16](images/lab1-02-create-vpc-settings.jpg)

3. Scroll down and choose **Create VPC**.

   ![Create VPC button](images/lab1-03-create-vpc-button.jpg)

4. The new VPC is empty: the resource map shows **no subnets** and only the main route table. There's no way to the internet yet. Next, open **Subnets**.

   ![ecs-vpc created – no subnets yet](images/lab1-04-vpc-created.jpg)

## 2. Subnets

**What is a subnet?** A slice of the VPC's address range that lives in **one Availability Zone**. You launch instances into a subnet, not directly into the VPC.

**What is an Availability Zone (AZ)?** One or more separate data centers inside a Region, with their own power and networking. Subnets in two AZs mean that one data-center failure doesn't take everything down, and some services require it: an Application Load Balancer needs subnets in **at least two AZs**.

**Why `/24` subnets?** `10.0.1.0/24` and `10.0.2.0/24` give 256 addresses each (AWS reserves 5 in every subnet, so **251 are usable**). The two ranges don't overlap, and most of `10.0.0.0/16` stays free for more subnets later.

| Subnet name | Availability Zone | IPv4 subnet CIDR block |
|-------------|-------------------|------------------------|
| **`ecs-public-1a`** | `us-east-1a` | **`10.0.1.0/24`** |
| **`ecs-public-1b`** | `us-east-1b` | **`10.0.2.0/24`** |

1. **VPC → Subnets → Create subnet**. (If your account has a default VPC, you also see its subnets here.)

   ![Subnets – Create subnet](images/lab1-05-subnets.jpg)

2. VPC ID: choose **`ecs-vpc`**.

   ![Create subnet – select ecs-vpc](images/lab1-06-subnet-select-vpc.jpg)

3. Subnet name **`ecs-public-1a`**, Availability Zone **`us-east-1a`**.

   ![Availability Zone us-east-1a](images/lab1-07-subnet-az.jpg)

4. IPv4 subnet CIDR block **`10.0.1.0/24`**. Then choose **Add new subnet**.

   ![Subnet ecs-public-1a – us-east-1a – 10.0.1.0/24](images/lab1-08-subnet-1a.jpg)

5. Second subnet: **`ecs-public-1b`**, **`us-east-1b`**, **`10.0.2.0/24`** → **Create subnet**.

   ![Subnet ecs-public-1b – us-east-1b – 10.0.2.0/24](images/lab1-09-subnet-1b.jpg)

6. Both subnets are created, in two Availability Zones.

   ![Two subnets created](images/lab1-10-subnets-created.jpg)

7. Select **`ecs-public-1a`** → **Actions → Edit subnet settings**.

   ![Actions – Edit subnet settings](images/lab1-11-edit-subnet-settings.jpg)

8. Check **Enable auto-assign public IPv4 address** → **Save**. Do the same for **`ecs-public-1b`**. Instances launched in these subnets now get a public IPv4 address **by default**, unless their launch settings turn it off (for example, a launch template or the ECS cluster's *Auto-assign public IP* setting). A public address alone isn't enough to reach the internet: the subnet also needs a route to an internet gateway (steps 3 and 4).

   ![Enable auto-assign public IPv4 address](images/lab1-12-auto-assign-ip.jpg)

## 3. Internet gateway

**What is an internet gateway?** It connects a VPC to the internet: traffic between your public subnets and the internet passes through it. AWS runs and scales it for you, and it has no hourly charge. A VPC can have **one** internet gateway, and it does nothing until you **attach** it and add a **route** to it.

1. **VPC → Internet gateways → Create internet gateway**.

   ![Internet gateways – Create internet gateway](images/lab1-13-internet-gateways.jpg)

2. Name tag **`ecs-igw`** → **Create internet gateway**.

   ![Create internet gateway ecs-igw](images/lab1-14-create-igw.jpg)

3. The new gateway is **Detached**: it isn't connected to any VPC. Choose **Attach to a VPC**.

   ![ecs-igw – Detached – Attach to a VPC](images/lab1-15-igw-detached.jpg)

4. Available VPCs: choose **`ecs-vpc`**.

   ![Attach to VPC – ecs-vpc](images/lab1-16-igw-attach-vpc.jpg)

5. Choose **Attach internet gateway**.

   ![Attach internet gateway](images/lab1-17-igw-attach-button.jpg)

6. The state changes to **Attached**. Next, open **Route tables**.

   ![ecs-igw – Attached](images/lab1-18-igw-attached.jpg)

## 4. Route table

**What is a route table?** A set of rules (**routes**) that decides where traffic from a subnet goes, by destination address. Every VPC has a **main route table** with one route, `local`, which keeps traffic for the VPC's own range (`10.0.0.0/16`) inside the VPC. Each subnet uses exactly one route table: the main one, unless you associate it with another.

Right now both subnets use the main route table, so traffic can't leave the VPC yet.

1. **VPC → Route tables → Create route table**. Each VPC already has a main route table.

   ![Route tables – Create route table](images/lab1-19-route-tables.jpg)

2. Name **`ecs-public-rt`**, VPC: choose **`ecs-vpc`**.

   ![Create route table – select ecs-vpc](images/lab1-20-create-rt-vpc.jpg)

3. Choose **Create route table**.

   ![Create route table ecs-public-rt](images/lab1-21-create-rt.jpg)

4. The new table has only the `local` route. Choose **Edit routes**.

   ![ecs-public-rt – local route only – Edit routes](images/lab1-22-rt-local-only.jpg)

5. **Add route** → Destination **`0.0.0.0/0`** (anywhere).

   ![Destination 0.0.0.0/0](images/lab1-23-route-destination.jpg)

6. Target: **Internet Gateway**.

   ![Target – Internet Gateway](images/lab1-24-route-target-type.jpg)

7. Choose **`ecs-igw`**.

   ![Target – ecs-igw](images/lab1-25-route-target-igw.jpg)

8. Choose **Save changes**.

   ![0.0.0.0/0 → ecs-igw – Save changes](images/lab1-26-route-save.jpg)

9. The table now has two routes: `0.0.0.0/0` → `ecs-igw`, and `local`. Open the **Subnet associations** tab.

   ![Routes – 0.0.0.0/0 to the internet gateway](images/lab1-27-route-saved.jpg)

10. Both subnets still use the main route table. Choose **Edit subnet associations**.

    ![Subnet associations – Edit subnet associations](images/lab1-28-subnet-associations.jpg)

11. Select **both** subnets → **Save associations**.

    ![Select ecs-public-1a and ecs-public-1b – Save associations](images/lab1-29-select-subnets.jpg)

A subnet whose route table sends `0.0.0.0/0` to an internet gateway is a **public subnet**. Both subnets are public now.

## 5. Check

Open `ecs-vpc` → **Resource map**. You should see the whole chain: the VPC → the two subnets → `ecs-public-rt` → `ecs-igw`. The second, unnamed route table is the main route table, which no subnet uses now.

![ecs-vpc resource map: two public subnets, ecs-public-rt, ecs-igw](images/lab1-30-resource-map.jpg)

**The next labs run in this network.** In the Containers labs, wherever a step says "the default VPC", use **`ecs-vpc`** and the subnets **`ecs-public-1a`** and **`ecs-public-1b`**. Keep the network: don't delete it when you finish.

---

## What's next?

Two ways to continue:

1. **[Containers – Lab 1: ECS on EC2](../3.06-containers/jb-lab-1.md):** build an ECS cluster on EC2 instances inside this network.
2. **[Advanced Networking](../3.08-advanced-vpc/README.md):** private and isolated subnets, NAT gateways, VPC endpoints, VPC peering and Transit Gateway, and IP address planning.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
