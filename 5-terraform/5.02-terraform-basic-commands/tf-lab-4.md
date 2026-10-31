# 5.02 Terraform Basic Commands – Lab 4: Outputs and Provisioners

[⬅ Lab 3](tf-lab-3.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-4-solution/README.md)

[![Video: Terraform – Outputs and provisioners](https://img.youtube.com/vi/NPedJ0Rr3Q4/maxresdefault.jpg)](https://youtu.be/NPedJ0Rr3Q4)

At the end of Lab 3, you couldn't reach the instances, and you had to open the Console to find their IP addresses. In this lab you give the instances a way in from the internet, ask Terraform for their IP addresses with **outputs**, save the addresses to a file with a **provisioner**, and connect to the instances with SSH from your computer.

## Providers and provisioners

A **provider** (like the AWS provider) creates resources. A **provisioner** runs an action when Terraform creates a resource. Provisioners are built into Terraform, so there's nothing to install:

| Provisioner | What it does | Where it runs |
|---|---|---|
| `local-exec` | Runs a command | On your computer, where you run `terraform apply` |
| `remote-exec` | Runs commands | On the new instance, over SSH (needs a `connection` block) |
| `file` | Copies a file or a folder | From your computer to the new instance, over SSH (needs a `connection` block) |

In this lab you use `local-exec`. Inside a provisioner, `self` is the resource it belongs to, so `self.public_ip` is this instance's public IP address.

An **output** prints a value that Terraform knows, like an attribute of a resource. Terraform prints the outputs at the end of `apply` and saves them in the state file, and `terraform output` prints them again at any time. The **Attribute Reference** on each resource page in the Terraform Registry lists the values you can print.

## What you add

| What | Settings |
|---|---|
| SSH key | `my-ssh-key` (private) and `my-ssh-key.pub` (public), made with `ssh-keygen` |
| Key pair | `tf-lab-key`, from `my-ssh-key.pub` |
| Public IP | New instances in `training-subnet-1a` get a public IP address |
| Internet gateway | `training-igw`, attached to `training-vpc` |
| Route table | `training-public-rt`: `0.0.0.0/0` to the internet gateway, used by `training-subnet-1a` |
| Security group | `training-ssh`: SSH (port 22) only from your IP address, and all outbound traffic |
| Instances | `my-tf-web-1` and `my-tf-web-2` get the key pair, the security group, and a `local-exec` provisioner that writes their IP addresses to `LAB-IPS.txt` |
| Outputs | `web_1_public_ip` and `web_2_public_ip` |

Region: **`us-east-1`**.

Before you start:
- [Lab 3](tf-lab-3.md): this lab continues from its folder, `tf-lab-3`.
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)).
- An SSH client: built into macOS, Linux and Windows 10 or later.

> 💰 **Cost:** two small instances and their public IPv4 addresses, for the length of the lab, cost a few cents. They keep costing money until you destroy them (step 13).

## Steps

1. **Copy the Lab 3 folder** to a new folder, and work there:
   ```bash
   cp -r tf-lab-3 tf-lab-4
   cd tf-lab-4
   ```
   - If you kept the resources from Lab 3, the copy includes their state file (`terraform.tfstate`). From now on, run Terraform only in `tf-lab-4`.
   - If you destroyed them, Terraform creates them again in this lab.
2. **Create an SSH key** in the `tf-lab-4` folder, with no passphrase for this lab:
   ```bash
   ssh-keygen -t ed25519 -f my-ssh-key -N ""
   ```
   - It creates `my-ssh-key`, the private key, which stays on your computer, and `my-ssh-key.pub`, the public key, which you upload to AWS.
   - If the folder is in Git, add `my-ssh-key`, `my-ssh-key.pub`, `LAB-IPS.txt` and `terraform.tfstate*` to `.gitignore`. Never commit the private key.
3. **The key pair.** In a new file, `key.tf`, add an [`aws_key_pair`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) resource:
   - start from the **Example Usage** on its page, and name it `tf-lab-key`;
   - instead of pasting the key as text, read it from the file: `public_key = file("my-ssh-key.pub")`.
4. **A way in from the internet.** In `vpc.tf`:
   - in the subnet, add `map_public_ip_on_launch = true`, so new instances get a public IP address;
   - add an [`aws_internet_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) attached to your VPC, named `training-igw`;
   - add an [`aws_route_table`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table), named `training-public-rt`, with one route: `0.0.0.0/0` to the internet gateway;
   - connect the subnet to it with an [`aws_route_table_association`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association).
5. **The security group.** In a new file, `security.tf`:
   - an [`aws_security_group`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) named `training-ssh`, in your VPC;
   - an `aws_vpc_security_group_ingress_rule`: TCP port 22, from `var.MY_IP`;
   - an `aws_vpc_security_group_egress_rule`: all outbound traffic (`ip_protocol = "-1"`) to `0.0.0.0/0`.
6. **Your IP address.** In `vars.tf`, add a variable named `MY_IP` (`type = string`, no default), and set it from the shell:
   - macOS and Linux:
     ```bash
     export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
     ```
   - Windows PowerShell:
     ```powershell
     $env:TF_VAR_MY_IP = "$((Invoke-RestMethod https://checkip.amazonaws.com).Trim())/32"
     ```
   - `/32` means this one address only.
7. **The instances.** In `instance.tf`, add to both instances:
   - `vpc_security_group_ids = [aws_security_group.ssh.id]` and `key_name = aws_key_pair.lab.key_name`;
   - `depends_on = [aws_internet_gateway.main]`: the instances don't refer to the internet gateway, so you set the order yourself;
   - a `local-exec` provisioner:
     ```hcl
     provisioner "local-exec" {
       command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
     }
     ```
8. **The outputs.** In a new file, `outputs.tf`, add two outputs, `web_1_public_ip` and `web_2_public_ip`:
   - find the attribute you need in the [**Attribute Reference**](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#attribute-reference) of `aws_instance`.
9. **Run `terraform init`**, and then **`terraform plan`**. Read the plan:
   - how many resources will it create, change or replace?
   - what does it show under **Changes to Outputs**?
10. **Run `terraform apply`**, and type `yes`.
    - Watch for `Provisioning with 'local-exec'...` after each instance is created.
    - Read the **Outputs** at the end.
11. **Check the IP addresses:**
    - `cat LAB-IPS.txt` (on Windows, `type LAB-IPS.txt`);
    - `terraform output`.
12. **Connect** to `my-tf-web-1`, with the IP address from the output:
    ```bash
    ssh -i my-ssh-key ec2-user@<web_1_public_ip>
    ```
    - The first time, type `yes` to accept the server's fingerprint.
    - If SSH times out right after `apply`, wait a minute: the instance may still be starting.
    - Type `exit` to leave.
13. **Clean up:** run `terraform destroy`, and type `yes`.
    - `LAB-IPS.txt`, `my-ssh-key` and `my-ssh-key.pub` stay in your folder.

## Questions

1. Where does `local-exec` run, and where do `remote-exec` and `file` run?
2. Why does the plan show your outputs as `(known after apply)`?
3. If you kept the resources from Lab 3, why does the plan replace the two instances?
4. You run `terraform apply` again with no changes. Does `LAB-IPS.txt` get new lines? Why?
5. After `terraform destroy`, why is `LAB-IPS.txt` still in your folder?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-4-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
