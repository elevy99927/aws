# 3.01 Compute: Amazon EC2 – Lab 2: Connect with SSH, Run a Container, and Clean Up

[⬅ Lab 1](lab-1.md) | [⬅ Back to 3.01 EC2](README.md) | [Solution ➡](lab-2-solution.md)

**▶ Video walkthrough** (7 min):

[![Video: EC2 – Connect with SSH and run a container](https://img.youtube.com/vi/paAiY6g03wQ/maxresdefault.jpg)](https://youtu.be/paAiY6g03wQ)

In this lab you use the instance from [Lab 1](lab-1.md): you log in to it with **SSH**, open **port 80** in its security group, install **Docker**, run a small web server in a container, and open it in your browser. At the end you **stop** and **terminate** the instance, so it stops costing money.

Region: **`us-east-1`**.

![lab-ec2 in ecs-public-1a, inside lab-ec2-sg: Lab 2 adds the Docker container elevy99927/color:blue on port 80 and the inbound rule HTTP 80 from My IP](images/ec2-labs.jpg)

<sub>Diagram source: [images/ec2-labs.drawio](images/ec2-labs.drawio)</sub>

> **Prerequisite:** [Lab 1](lab-1.md): the instance **`lab-ec2`** is **Running**, its security group **`lab-ec2-sg`** allows SSH from your IP, and you have the private key **`lab-ec2-key.pem`**.

> 💰 **Cost:** the instance is billed while it runs (see [Lab 1](lab-1.md)). A **stopped** instance costs nothing for compute, but its EBS volume is still billed. **Terminate** it at the end (step 6) and nothing from this lab keeps costing money.

---

## Steps

### 1. Connect with SSH

**What is SSH?** *Secure Shell* gives you an encrypted terminal on a remote computer, over **TCP port 22**. Instead of a password, your SSH client proves who you are with the **private key**, and the instance checks that proof with the **public key** it got at launch. The private key never leaves your computer.

1. In the Console, select `lab-ec2` → **Connect** → **SSH client**. The page shows the exact commands for this instance.
2. On your computer, open a terminal and run the commands. Use the path where you saved the key, and your instance's address: the Console may show a **public DNS name** (`ec2-…compute-1.amazonaws.com`) instead of the IP, and both work.

   ```bash
   chmod 400 ~/.ssh/lab-ec2-key.pem
   ssh -i ~/.ssh/lab-ec2-key.pem ec2-user@<public-ip>
   ```

3. The first time, SSH shows the host's **key fingerprint** and asks whether you trust it. To be thorough, compare it with the [instance's fingerprint](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connection-prereqs-general.html#connection-prereqs-fingerprint), then type **`yes`**. The Amazon Linux banner and the prompt `[ec2-user@ip-10-0-1-… ~]$` mean you're in.

> **Windows 10/11:** PowerShell has the same `ssh` command. Instead of `chmod 400`, make the key readable only by you: `icacls lab-ec2-key.pem /inheritance:r /grant:r "$($env:USERNAME):(R)"`. Then run `icacls lab-ec2-key.pem` and check that only your user is listed; remove any other user or group with `icacls lab-ec2-key.pem /remove "<name>"`. Use the same key path in the `ssh` command.

### 2. Open port 80 in the security group

**Why?** The web server will listen on port **80** (HTTP), and the security group blocks every inbound port that has no rule. Security groups are **stateful**: you add a rule for the incoming request only, and the replies go back out automatically.

1. Instance → **Security** tab → the security group **`lab-ec2-sg`** → **Edit inbound rules**.
2. **Add rule:** Type **HTTP** (TCP 80), Source type **My IP** → **Save rules**.

The change takes effect right away, without restarting the instance.

### 3. Install Docker

In your SSH session, on the instance:

```bash
sudo dnf install -y docker
sudo systemctl enable --now docker
sudo docker --version
sudo systemctl is-active docker
```

`sudo` runs a command as the administrator (root). `dnf` is the package manager of Amazon Linux 2023. `systemctl enable --now` starts Docker now and at every boot, and `is-active` prints `active` when it runs. New to Docker? See the [Docker tutorial](https://github.com/elevy99927/docker).

### 4. Run the container

```bash
sudo docker run -d --name color -p 80:80 elevy99927/color:blue
sudo docker ps
curl -s localhost | grep Hello
```

- `-d` runs the container in the background.
- `-p 80:80` maps **port 80 on the instance** to **port 80 in the container** (nginx).
- `curl localhost` sends a web request to the instance itself: you should see `Hello blue`.

### 5. Browse to the site

On your computer, open **`http://<public-ip>`** (http, not https). You should see a blue page with **Hello blue**.

Traffic path: your browser → internet → `ecs-igw` → the security group (HTTP 80 from your IP) → the instance's port 80 → the container.

### 6. Stop and terminate the instance

**Stop or terminate?**

| | **Stop** | **Terminate** |
|---|---|---|
| The instance | Shut down, can be started again | **Deleted**, can't be undone |
| Compute charges | None while stopped | None |
| Root EBS volume | Kept, **still billed** | Deleted (by default) |
| Auto-assigned public IP | Released (a new one at the next start) | Released |

1. **Instance state → Stop instance → Stop.** Wait for **Stopped**: the public IPv4 address is gone.
2. **Instance state → Terminate (delete) instance → Terminate (delete).** Wait for **Terminated**. The instance stays in the list for a while, then disappears.
3. **Clean up the rest** (free, but tidy):
   - **EC2 → Security Groups** → `lab-ec2-sg` → **Actions → Delete security groups** (after the instance is terminated, and if nothing else uses it).
   - **EC2 → Key Pairs** → `lab-ec2-key` → **Actions → Delete** (if no other instance uses it), and delete `lab-ec2-key.pem` on your computer.
   - **Keep `ecs-vpc`:** later labs use it.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `ssh: connect to host … port 22: Operation timed out` | Your current public IP isn't the one in the rule. A VPN, a new network, or a network with **more than one public IP** changes it. Run `curl https://checkip.amazonaws.com` on the same computer and add that address (`/32`) to the SSH rule. |
| `WARNING: UNPROTECTED PRIVATE KEY FILE!` | The key file is readable by others. Run `chmod 400 ~/.ssh/lab-ec2-key.pem`. |
| `Permission denied (publickey)` | Wrong user or wrong key. Amazon Linux uses **`ec2-user`**, and the key must be the one chosen at launch. |
| The browser can't open the page, but `curl` on the instance works | Check the HTTP rule's source the same way as for SSH. Type `http://`: browsers in *HTTPS-only* mode may refuse plain HTTP. `curl http://<public-ip>` from your computer is a quick test. |
| `docker: permission denied … docker.sock` | Run Docker commands with `sudo`. |
| `no matching manifest for linux/arm64` or `exec format error` | The instance is Arm (for example `t4g`). This image needs **x86**, see Lab 1, step 2. |

---

## Check yourself

1. After you **stop** the instance, why does it have **no public IPv4 address**?
2. A stopped instance has no compute charge. What can **still cost money**?
3. What does **`-p 80:80`** connect, and why does the security group need port 80, not some other port?

The answers are at the end of the [solution](lab-2-solution.md#answers).

---

## Solution

[lab-2-solution.md](lab-2-solution.md): the Console and the terminal, step by step with screenshots (Solution 1), and the whole lab with the AWS CLI (Solution 2).

## What's next?

Back to the [3.01 EC2 chapter](README.md) for the next topics: user data, AMIs and EBS snapshots. More on disks in [3.02 Storage](../3.02-storage/README.md).

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
