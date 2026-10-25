# 2.04 VPC and Networking – Labs 2–4

[⬅ Lab 1](lab-1.md) | [⬅ Back to 2.04 VPC and Networking](README.md) | [Solutions ➡](SOLUTION.md)

> Start with **[Lab 1: Build a VPC with Public Subnets](lab-1.md)**. These labs build on what it teaches.

---

## 🧪 LAB 2 (Basic): Explore the Default VPC

**Goal:** Understand what AWS creates for you in every Region.

**Tools:** Console + AWS CLI. Complete [00 Getting Started](../00-getting-started/README.md) first. The examples use `us-east-1`.

> **No default VPC in your Region?** Then explore the VPC you built in [Lab 1](lab-1.md) (`ecs-vpc`) instead: it has the same building blocks. Lab 1 already built a VPC by hand; this lab looks at the same pieces from a different angle. To bring the default VPC back: **Actions → Create default VPC**, or `aws ec2 create-default-vpc` (free).

### Tasks

1. Open the **VPC** console and choose **Your VPCs**. Find the VPC where **Default VPC = Yes**. What is its CIDR?
2. Select it and open the **Resource map** tab. How many subnets are there? How many route tables? Is there an Internet Gateway?
3. Choose **Subnets** and filter by the default VPC:
   - Which AZ is each subnet in?
   - What is the size (prefix) of each subnet?
   - Is **Auto-assign public IPv4 address** enabled?
4. Open the **main route table**. Which route makes the default subnets public?
5. Repeat steps 1–4 with the AWS CLI.

### Questions

- Why is every default subnet public?
- How many usable IPs does a default subnet have?
- What happens if you run `aws ec2 create-default-vpc` in a Region that already has a default VPC?

---

## 🧪 LAB 3 (Basic): Create a VPC with the "VPC and more" Wizard

**Goal:** Create a production-style VPC with public and private subnets in two AZs, in a few clicks.

**Tools:** Console.

### Tasks

1. In the **VPC** console, choose **Create VPC → VPC and more**.
2. Configure:
   - **Name tag auto-generation:** `lab`
   - **IPv4 CIDR block:** `10.0.0.0/16`
   - **Number of Availability Zones:** `2`
   - **Number of public subnets:** `2`
   - **Number of private subnets:** `2`
   - **NAT gateways:** `None` (to avoid charges)
   - **VPC endpoints:** `None`
3. Look at the **Preview** on the right side **before** you create it. Which subnet is associated with which route table?
4. Choose **Create VPC** and wait for all the steps to finish.
5. Open the new VPC's **Resource map**. Compare the public and private route tables.
6. **Clean up:** select the VPC, then choose **Actions → Delete VPC**. This also deletes its subnets, route tables and IGW.

### Questions

- What is the difference between the public and the private route tables?
- Could an instance in a private subnet download updates from the internet? What would you add?

---

## 🧪 LAB 4 (Advanced): Build a VPC Piece by Piece with the CLI

**Goal:** Understand every building block by creating a VPC manually. You'll create a VPC, a public and a private subnet, an Internet Gateway and a public route table.

**Tools:** AWS CLI.

### Tasks

1. Create a VPC `lab-cli-vpc` with CIDR `10.10.0.0/16`.
2. Create two subnets:
   - `lab-public-a`: `10.10.1.0/24` in the **first** AZ
   - `lab-private-b`: `10.10.11.0/24` in the **second** AZ
3. Enable **auto-assign public IPv4** on `lab-public-a`.
4. Create an **Internet Gateway** `lab-igw` and **attach** it to the VPC.
5. Create a route table `lab-public-rt`. Add the route `0.0.0.0/0 → IGW` and **associate** it with `lab-public-a` only.
6. Verify the setup:
   - The route table of `lab-public-a` has a route to the IGW.
   - `lab-private-b` uses the **main** route table, which has only the `local` route.
7. Open the VPC's **Resource map** in the Console and compare it with what you built.
8. **Clean up** in the correct order. Detach and delete the IGW, then delete the subnets, the route table and the VPC.

### Questions

- Why does `lab-private-b` stay private even though it is in the same VPC as the IGW?
- Why must you detach the IGW before you can delete the VPC?

---

## Solutions

Step-by-step solutions for Labs 2–4: **[SOLUTION.md](SOLUTION.md)**

---

[⬅ Lab 1](lab-1.md) | [⬅ Back to 2.04 VPC and Networking](README.md) | [Solutions ➡](SOLUTION.md)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
