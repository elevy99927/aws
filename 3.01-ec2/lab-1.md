# 3.01 Compute: Amazon EC2 – Lab 1: Launch Your First EC2 Instance

[⬅ Back to 3.01 EC2](README.md) | [Solution ➡](lab-1-solution.md) | [Lab 2 ➡](lab-2.md)

**▶ Video walkthrough** (7 min):

[![Video: EC2 – Launch your first EC2 instance](https://img.youtube.com/vi/guJMkW6rb7g/maxresdefault.jpg)](https://youtu.be/guJMkW6rb7g)

In this lab you launch a virtual server, an **EC2 instance**, from the Console's **Launch an instance** page, as simply as possible. You choose an operating system image (AMI), a size (instance type), a key pair for logging in, the network, and a disk. In [Lab 2](lab-2.md) you log in to this instance, run a container on it, and then delete it.

Region: **`us-east-1`** (N. Virginia).

![What you build: the instance lab-ec2 (t3.micro, Amazon Linux 2023) in the public subnet ecs-public-1a of ecs-vpc, inside the security group lab-ec2-sg, with an 8 GiB gp3 root EBS volume; your computer reaches it through the internet and ecs-igw on SSH port 22 (Lab 1) and HTTP port 80 (Lab 2)](images/ec2-labs.jpg)

<sub>Diagram source: [images/ec2-labs.drawio](images/ec2-labs.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

> **Prerequisite:** the network from [2.04 VPC and Networking – Lab 1](../2.04-vpc-and-networking/lab-1.md): **`ecs-vpc`** with the public subnets **`ecs-public-1a`** and **`ecs-public-1b`**. No new network is needed for this lab.
>
> **Don't have a VPC yet?** If your account still has its **default VPC** in `us-east-1`, use it: every default subnet is public. Step 5 shows what to choose. If the page says *"We have detected that your account has no VPCs in this region"*, either build `ecs-vpc` with the 2.04 lab, or create a default VPC: **VPC → Your VPCs → Actions → Create default VPC** (or `aws ec2 create-default-vpc`). Both are free.

> 💰 **Cost:** an EC2 instance is billed **while it runs**. `t3.micro` is **Free Tier eligible**, but outside the Free Tier it costs about **$0.0104 an hour** in `us-east-1` (Linux, on-demand), plus **$0.005 an hour** for its public IPv4 address and about **$0.08 per GB-month** for the gp3 disk. Running Lab 1 and Lab 2 back to back costs a few cents. T3 instances launch in *unlimited* mode by default: if the CPU stays busy above its baseline, extra CPU credits may be billed, even during a short lab. Delete the instance at the end of [Lab 2](lab-2.md#6-stop-and-terminate-the-instance), or right away if you stop here.

---

## Steps

Open **EC2 → Instances → Launch instances**. The page is one long form, top to bottom.

### 1. Name

Name the instance **`lab-ec2`**. The name is a **tag** (`Name = lab-ec2`): a label that helps you find the instance later. It doesn't change how the instance works.

### 2. Application and OS Images (AMI)

**What is an AMI?** An **Amazon Machine Image** is the template the instance starts from: the operating system, and sometimes ready-installed software. *Quick Start* lists the common ones.

- Choose **Amazon Linux** → **Amazon Linux 2023 AMI** (*Free tier eligible*).
- Architecture: **64-bit (x86)**. The other option, *64-bit (Arm)*, runs on AWS Graviton processors. The container image you run in Lab 2 is built for x86 (`amd64`) only, so this lab needs x86.
- Note the **username**: `ec2-user`. You log in with it in Lab 2.

### 3. Instance type

**What is an instance type?** The size of the server: how many vCPUs, how much memory, and how fast its network is. The name tells you the family, generation and size: `t3.micro` is family **t** (general purpose, *burstable* CPU), generation **3**, size **micro** (2 vCPUs, 1 GiB memory). *Burstable* means the CPU runs at a baseline and can burst above it for short periods.

Choose **`t3.micro`**.

**Free Tier, in short:** *Free tier eligible* means the type is included in the Free Tier, **not** that it's always free. What you get depends on when your account was created:

- Accounts created **before 15 July 2025**: 750 hours a month of `t2.micro` or `t3.micro` for the first 12 months.
- Newer accounts: **up to $200 in credits** for 6 months. On the **Free plan** nothing is billed, and the account closes when the credits or the 6 months run out (unless you upgrade). On a **Paid plan**, usage beyond the credits is billed.

The price in the Instance type box is for **compute only**: the disk and the public IPv4 address are billed separately. Check your account's plan before you launch.

### 4. Key pair (login)

**What is a key pair?** Two matching keys for SSH login. AWS keeps the **public key** and puts it on the instance. You download the **private key** (a `.pem` file) **once**: AWS doesn't keep a copy, so if you lose it, you can't log in with this key pair.

Choose **Create new key pair**: name **`lab-ec2-key`**, type **RSA**, format **`.pem`** (for OpenSSH: macOS, Linux and Windows 10/11). Then choose **Create key pair**. The browser downloads `lab-ec2-key.pem`. Keep it, and never share it: you need it in Lab 2. On macOS or Linux, move it to `~/.ssh` and make it readable only by you:

```bash
mkdir -p ~/.ssh
mv ~/Downloads/lab-ec2-key.pem ~/.ssh/
chmod 400 ~/.ssh/lab-ec2-key.pem
```

On Windows, see [Lab 2, step 1](lab-2.md#1-connect-with-ssh).

### 5. Network settings

**Where does the instance live?** In a **subnet** of a **VPC**. A **public subnet** has a route to the internet gateway. For the direct SSH connection in Lab 2, the instance also needs a **public IPv4 address**.

Choose **Edit**, then:

- VPC: **`ecs-vpc`**. Subnet: **`ecs-public-1a`**.
- Auto-assign public IP: **Enable**.
- Firewall (security groups): **Create security group**, name **`lab-ec2-sg`**, description **`SSH from my IP`**.
- Inbound rule: Type **ssh** (TCP port 22), Source type **My IP**. SSH (*Secure Shell*) opens a terminal on the instance over the network: you use it in Lab 2.

**What is a security group?** A firewall around the instance. Inbound traffic is **blocked unless a rule allows it**, and all outbound traffic is allowed. *My IP* fills in your current public address with **`/32`**, which means exactly one address. That's much safer than *Anywhere* (`0.0.0.0/0`), which lets the whole internet try to log in.

> **Using a default VPC?** Choose **Edit** too: select the default VPC and any default subnet, check that *Auto-assign public IP* is **Enable**, and create **`lab-ec2-sg`** as above, so that Lab 2 finds it.

### 6. Configure storage

**What is EBS?** **Elastic Block Store** is a network disk attached to the instance. The **root volume** holds the operating system.

Keep the default: **1 × 8 GiB gp3** root volume. `gp3` is the general-purpose SSD type. The other volume types (gp2, io1/io2, st1, sc1) come later, in [3.02 Storage](../3.02-storage/README.md).

### 7. Launch and check

1. Check the **Summary** on the right: 1 instance, Amazon Linux 2023, `t3.micro`, a new security group, one 8 GiB volume. Choose **Launch instance**.
2. Open **Instances**. Wait until `lab-ec2` shows **Running** and **3/3 checks passed** (about a minute or two).
3. Select it and note its **Public IPv4 address**. You connect to it in Lab 2.

**Continue to [Lab 2](lab-2.md) now?** Keep the instance running. **Stopping here?** Follow Lab 2's cleanup steps to terminate the instance and delete the security group and key pair: see [Lab 2, step 6](lab-2.md#6-stop-and-terminate-the-instance).

---

## Check yourself

1. Why did you choose **64-bit (x86)** and not Arm?
2. What does **`/32`** mean in the SSH rule's source?
3. What happens to the **root EBS volume** when you terminate the instance?

The answers are at the end of the [solution](lab-1-solution.md#answers).

---

## Solution

[lab-1-solution.md](lab-1-solution.md): the Console, click by click with screenshots (Solution 1), and the same instance with the AWS CLI (Solution 2).

## What's next?

**[Lab 2: Connect with SSH, run a container, and clean up](lab-2.md)**: log in with your key, open port 80, install Docker, run a web container, browse to it, and then stop and terminate the instance.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
