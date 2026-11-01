# 5.02 Terraform Basic Commands – Lab 5: Remote State in S3, User Data and remote-exec

[⬅ Lab 4](tf-lab-4.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-5-solution/README.md)

[![Video: Terraform – Remote state, user data and remote-exec](https://img.youtube.com/vi/O5jGy-GkvPE/maxresdefault.jpg)](https://youtu.be/O5jGy-GkvPE)

Until now, the state file, `terraform.tfstate`, lived in your folder. Lose the folder, and Terraform forgets everything it built; work from a second computer, and it doesn't know the resources exist. In this lab you move the state to an S3 bucket, where any computer with access can use it, and Terraform locks it while a command runs. Then you give the instances a job: **user data** installs a web server at their first boot, and a **remote-exec** provisioner connects over SSH to check that it works.

## Remote state, user data and remote-exec

| | What it is | Where it runs |
|---|---|---|
| **Remote state** (`backend "s3"`) | The state file is stored in an S3 bucket instead of your folder, with a lock file while a command runs | S3 |
| **User data** (`user_data`) | A script the instance runs once, as root, at its first boot (cloud-init runs it) | On the instance, without Terraform watching |
| **`remote-exec`** | A provisioner: Terraform connects over SSH and runs commands; if one fails, the apply fails | On the instance, from Terraform |

## What you add

| What | Settings |
|---|---|
| State bucket | `tfstate-<yourname>-<random number>`, for example `tfstate-dana-4821`, with versioning, created with the AWS CLI |
| Backend | `backend "s3"`: the bucket, the key `tf-lab-5/terraform.tfstate`, `us-east-1`, `use_lockfile = true` |
| User data | `install-nginx.sh`: installs nginx and writes a page with the instance's host name |
| Security group | A second inbound rule: HTTP (port 80) only from your IP address |
| Instances | `user_data`, `user_data_replace_on_change = true`, a `connection` block and a `remote-exec` provisioner |
| Outputs | `web_1_url` and `web_2_url` |

Region: **`us-east-1`**.

Before you start:
- [Lab 4](tf-lab-4.md): this lab continues from its folder, `tf-lab-4`, with its SSH key and its `TF_VAR_MY_IP`.
- The AWS CLI is signed in to your account ([Getting Started](../../00-getting-started/README.md)). The S3 backend uses the AWS CLI's sign-in (or the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables), not the provider's `TF_VAR_` variables.

> 💰 **Cost:** two small instances and their public IPv4 addresses for the length of the lab cost a few cents. The state bucket holds a few kilobytes, which costs nothing noticeable; keep it for the next labs.

## Steps

### Part 1: Remote state in S3

1. **Copy the Lab 4 folder** to a new folder, and work there:
   ```bash
   cp -r tf-lab-4 tf-lab-5
   cd tf-lab-5
   ```
   - If you destroyed the Lab 4 resources, run `terraform apply` once now, so there is a state to move.
   - Set your IP address again if this is a new terminal: `export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"`.
2. **Create the state bucket** with the AWS CLI, with your own name and a random number:
   ```bash
   aws s3api create-bucket --bucket tfstate-<yourname>-<number> --region us-east-1
   aws s3api put-bucket-versioning --bucket tfstate-<yourname>-<number> --versioning-configuration Status=Enabled
   aws s3api get-bucket-versioning --bucket tfstate-<yourname>-<number>
   ```
   - The last command checks versioning: it prints `"Status": "Enabled"`.
   - Terraform can't create the bucket that stores its own state: the bucket must exist before `terraform init`.
   - Versioning keeps every earlier version of the state, so a bad apply can be undone.
3. **The backend.** In a new file, `backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket       = "tfstate-<yourname>-<number>"
       key          = "tf-lab-5/terraform.tfstate"
       region       = "us-east-1"
       use_lockfile = true
     }
   }
   ```
   - A backend block can't use variables: write the values in.
   - `use_lockfile` writes a lock file next to the state while a command runs, so two people can't change it at the same time.
4. **Move the state:** run `terraform init -migrate-state`, and answer `yes` when Terraform asks to copy the existing state to the new backend.
5. **Check:**
   - `terraform plan` says **No changes**: Terraform reads the same state, now from S3.
     If your IP address changed since Lab 4 and you set `TF_VAR_MY_IP` again, the plan updates the SSH rule in place (`1 to change`): that's your new address, not a migration problem.
   - In the AWS Console, **S3 → your state bucket → `tf-lab-5/`**: the object `terraform.tfstate`.
   - Your local `terraform.tfstate` is now empty, and `terraform.tfstate.backup` holds the old copy: once `plan` says No changes, you can delete both.

### Part 2: User data and remote-exec

6. **The user-data script.** In a new file, `install-nginx.sh`:
   ```bash
   #!/bin/bash
   dnf install -y nginx
   echo "<h1>Hello from $(hostname)</h1><p>Installed by user-data</p>" \
     > /usr/share/nginx/html/index.html
   systemctl enable --now nginx
   ```
7. **HTTP from your IP.** In `security.tf`, add an `aws_vpc_security_group_ingress_rule` named `http`: TCP port 80, from `var.MY_IP`.
8. **The instances.** In `instance.tf`, add to both instances:
   - `user_data = file("install-nginx.sh")` and `user_data_replace_on_change = true`: user data runs only at the first boot, so a changed script needs a new instance;
   - a `connection` block, which tells Terraform how to reach the instance, and a `remote-exec` provisioner, before the `local-exec` one:
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
9. **The outputs.** In `outputs.tf`, add `web_1_url` and `web_2_url`: `"http://${aws_instance.web_1.public_ip}"` and the same for `web_2`.
10. **Run `terraform plan`.** Read it:
    - which resources are replaced, and why?
    - what does it add to the security group?
11. **Run `terraform apply`**, and type `yes`.
    - Watch the `remote-exec` lines: Terraform connects, waits for cloud-init, and prints `active` and the page.
    - **`remote-exec` times out?** The security group doesn't allow the address your computer really uses. Run `curl https://checkip.amazonaws.com` a few times:
      - **The same address every time,** but not the one in `TF_VAR_MY_IP`: set `TF_VAR_MY_IP` again. The next plan also updates the SSH and HTTP rules in place (`2 to change`).
      - **Different addresses:** your network uses more than one public IP. Allow the other one too, for the length of the lab: in the Console, **EC2 → Security Groups → your group → Edit inbound rules**, add SSH (22) and HTTP (80) from `<the other address>/32`. Terraform doesn't manage this rule; remove it at the end of the lab.

      Then run `terraform apply`. The failed instances are marked **tainted**, and the apply replaces them.
    - In a second terminal, while the apply runs, `aws s3 ls s3://<your state bucket>/ --recursive` shows the lock file `terraform.tfstate.tflock` next to the state.
12. **Open the page:** `curl` each URL from `terraform output`, or open it in a browser.
    - In the browser, type `http://` in full: this server doesn't serve `https://`. A timeout means the HTTP rule doesn't have your current address, as in step 11.
13. **Clean up:** run `terraform destroy`, and type `yes`.
    - Keep the state bucket for the next labs; it now holds an empty state.

## Questions

1. Why can't Terraform create the bucket that holds its own state, in the same configuration?
2. After `terraform init -migrate-state`, why does `terraform plan` show no changes?
3. You change one line in `install-nginx.sh` and run `terraform plan`. What happens to the instances, and why does the lab set `user_data_replace_on_change`?
4. User data and `remote-exec` both run commands on the instance. Which one does Terraform wait for, and which one can fail the apply?
5. What would a second person need, to work on the same infrastructure from another computer?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-5-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
