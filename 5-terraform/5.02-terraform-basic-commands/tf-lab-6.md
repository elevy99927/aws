# 5.02 Terraform Basic Commands – Lab 6: User Data and remote-exec

[⬅ Lab 5](tf-lab-5.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-6-solution/README.md) | [Lab 7 ➡](tf-lab-7.md)

The instances exist, you can reach them with SSH, and the state is safe in S3, but the instances do nothing yet. In this lab you give them a job: **user data** installs a web server at their first boot, and a **remote-exec** provisioner connects over SSH to check that it works, before the apply ends.

## User data and remote-exec

| | What it is | Where it runs |
|---|---|---|
| **User data** (`user_data`) | A script the instance runs once, as root, at its first boot (cloud-init runs it) | On the instance, without Terraform watching |
| **`remote-exec`** | A provisioner: Terraform connects over SSH and runs commands; if one fails, the apply fails | On the instance, from Terraform |

## What you add

| What | Settings |
|---|---|
| User data | `install-nginx.sh`: installs nginx and writes a page with the instance's host name |
| Security group | A second inbound rule: HTTP (port 80) only from your IP address |
| Instances | `user_data`, `user_data_replace_on_change = true`, a `connection` block and a `remote-exec` provisioner |
| Outputs | `web_1_url` and `web_2_url` |

Region: **`us-east-1`**.

Before you start:
- [Lab 5](tf-lab-5.md): this lab continues from its folder, `tf-lab-5`, with the state in S3, the lock table, the SSH key and `TF_VAR_MY_IP`.

> 💰 **Cost:** two small instances and their public IPv4 addresses for the length of the lab cost a few cents.

## Steps

### Part 1: User data

1. **Copy the Lab 5 folder** to a new folder, and work there:
   ```bash
   cp -r tf-lab-5 tf-lab-6
   cd tf-lab-6
   terraform init
   ```
   - The copy brings `backend.tf`, so the state stays in S3; `terraform init` connects the new folder to it.
   - Set your IP address again if this is a new terminal: `export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"`.
   - If you destroyed the Lab 5 resources, run `terraform apply` once now.
2. **The user-data script.** In a new file, `install-nginx.sh`:
   ```bash
   #!/bin/bash
   dnf install -y nginx
   echo "<h1>Hello from $(hostname)</h1><p>Installed by user-data</p>" \
     > /usr/share/nginx/html/index.html
   systemctl enable --now nginx
   ```
   - The install downloads nginx from the internet at the first boot, through the way out from Lab 4: the public IP, the internet gateway and its route, and the outbound rule.
3. **HTTP from your IP.** In `security.tf`, add an `aws_vpc_security_group_ingress_rule` named `http`: TCP port 80, from `var.MY_IP`.
4. **The instances.** In `instance.tf`, add to both instances `user_data = file("install-nginx.sh")` and `user_data_replace_on_change = true`: user data runs only at the first boot, so a changed script needs a new instance.

### Part 2: remote-exec

5. **The connection and the check.** In `instance.tf`, add to both instances a `connection` block and a `remote-exec` provisioner, before the `local-exec` one:
   ```hcl
   connection {
     type        = "ssh"
     user        = "ec2-user"
     private_key = file("my-ssh-key")
     host        = self.public_ip
   }

   provisioner "remote-exec" {
     inline = [
       "cloud-init status --wait",
       "systemctl is-active nginx",
       "curl -s localhost",
     ]
   }
   ```
   - `cloud-init status --wait` returns only when the user-data script has finished, so the next two commands check a finished install.
6. **The outputs.** In `outputs.tf`, add `web_1_url` and `web_2_url`: `"http://${aws_instance.web_1.public_ip}"` and the same for `web_2`.
7. **Run `terraform plan`.** Read it:
   - which resources are replaced, and why?
   - what does it add to the security group?
8. **Run `terraform apply`**, and type `yes`.
   - Watch the `remote-exec` lines: Terraform connects, waits for cloud-init, and prints `active` and the page.
   - **`remote-exec` times out?** Your public IP address isn't the one in `TF_VAR_MY_IP`: check it with `curl https://checkip.amazonaws.com`, set it again, and run `terraform apply` again.
9. **Open the page:** `curl` each URL from `terraform output`, or open it in a browser.
   - In the browser, type `http://` in full: this server doesn't serve `https://`.
10. **Clean up:** run `terraform destroy`, and type `yes`.
    - Keep the state bucket and the lock table for the next labs.

## Questions

1. You change one line in `install-nginx.sh` and run `terraform plan`. What happens to the instances, and why does the lab set `user_data_replace_on_change`?
2. User data and `remote-exec` both run commands on the instance. Which one does Terraform wait for, and which one can fail the apply?
3. Why does the `remote-exec` provisioner start with `cloud-init status --wait`?
4. What is `self.public_ip` in the `connection` block, and why does each instance connect to a different address?
5. The page says "Hello from ip-10-0-1-194.ec2.internal". Where does that name come from?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-6-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
