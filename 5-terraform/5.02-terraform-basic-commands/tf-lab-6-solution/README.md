# 5.02 Terraform Basic Commands – Lab 6 Solution

[⬅ Lab 6](../tf-lab-6.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the Lab 5 folder plus one new file and three changed ones:

| File | What it holds |
|---|---|
| [`install-nginx.sh`](install-nginx.sh) **new** | The user-data script: installs nginx and writes a page with the instance's host name |
| [`security.tf`](security.tf) | Lab 4's SSH rule, plus `aws_vpc_security_group_ingress_rule.http`: port 80 from `var.MY_IP` |
| [`instance.tf`](instance.tf) | Both instances get `user_data`, `user_data_replace_on_change = true`, a `connection` block and a `remote-exec` provisioner |
| [`outputs.tf`](outputs.tf) | Lab 4's IP outputs, plus `web_1_url` and `web_2_url` |
| [`backend.tf`](backend.tf), [`vars.tf`](vars.tf), [`provider.tf`](provider.tf), [`vpc.tf`](vpc.tf), [`key.tf`](key.tf), [`s3.tf`](s3.tf) | The same as in Lab 5: the state stays in S3, with the lock table |

Replace `tfstate-yourname-1234` in `backend.tf` with your own bucket name, and `s3-lab-yourname-1234` in `s3.tf` with your Lab 3 name. Your SSH key files, `my-ssh-key` and `my-ssh-key.pub`, come from your Lab 4 folder.

The terminal blocks below are from the real run. IDs and IP addresses are masked.

## Part 1: user data

`install-nginx.sh` runs once, as root, at the first boot of each instance:

```bash
#!/bin/bash
dnf install -y nginx
echo "<h1>Hello from $(hostname)</h1><p>Installed by user-data</p>" \
  > /usr/share/nginx/html/index.html
systemctl enable --now nginx
```

In `instance.tf`, both instances get the script, and the setting that replaces the instance when the script changes:

```hcl
resource "aws_instance" "web_1" {
  # ... as in Lab 4 ...
  user_data                   = file("install-nginx.sh")
  user_data_replace_on_change = true
```

## Part 2: remote-exec

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

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}
```

- `cloud-init status --wait` blocks until cloud-init has run the user-data script, so the next two commands check a finished install.
- Provisioners run in the order they're written: `remote-exec` first, then `local-exec`.

**The plan:**

```text
  # aws_instance.web_1 must be replaced
      + user_data                            = <<-EOT # forces replacement
      ~ user_data_replace_on_change          = false -> true
  # aws_instance.web_2 must be replaced
  ...
  # aws_vpc_security_group_ingress_rule.http will be created

Plan: 3 to add, 0 to change, 2 to destroy.
```

User data runs only at the first boot. Without `user_data_replace_on_change`, Terraform would update the user data on the existing instance (AWS stops and starts it), but cloud-init wouldn't run the script again; with it, Terraform replaces the instance, and the new one runs the script.

**The apply**, with the remote-exec lines:

```text
aws_instance.web_1 (remote-exec): Connected!
aws_instance.web_1 (remote-exec): status: done
aws_instance.web_1 (remote-exec): active
aws_instance.web_1 (remote-exec): <h1>Hello from ip-10-0-1-194.ec2.internal</h1><p>Installed by user-data</p>
...

Outputs:

web_1_url = "http://203.0.113.11"
web_2_url = "http://203.0.113.12"
```

```text
$ curl http://203.0.113.11
<h1>Hello from ip-10-0-1-194.ec2.internal</h1><p>Installed by user-data</p>
```

## Clean up

```text
$ terraform destroy
Plan: 0 to add, 0 to change, 13 to destroy.
Destroy complete! Resources: 13 destroyed.
```

13 resources: the 12 from Lab 4, plus the HTTP rule. The state in S3 is now an empty state, and the lock table keeps only its `-md5` item. Keep the bucket and the table for the next labs.

## Answers

1. **Both instances are replaced.** One changed line in `install-nginx.sh` changes `user_data`, and `user_data_replace_on_change = true` turns that into a replacement (`must be replaced`, `forces replacement`). Without that setting, Terraform would update the user data on the existing instances (AWS stops and starts them), but the new script wouldn't run, since cloud-init runs user data only at the first boot.
2. **Terraform waits for `remote-exec`**, and a failing command (or no SSH connection) fails the apply. **User data** runs inside the instance through cloud-init; Terraform doesn't wait for it and never sees its output, so a broken script doesn't fail the apply. This lab uses `remote-exec` to wait for user data and check its result.
3. **`cloud-init status --wait`** returns only when cloud-init has finished, including the user-data script. Without it, `systemctl is-active nginx` and `curl` would run while `dnf install` is still working, and fail.
4. **`self`** is the resource the provisioner belongs to, so `self.public_ip` is that instance's own public IP address: `web_1` connects to `web_1`'s address, and `web_2` to its own. The same `connection` block works for both because `self` is evaluated per instance.
5. **From the instance's host name.** The script writes `$(hostname)`, and an EC2 instance's host name is its private DNS name, built from its private IP: `ip-10-0-1-194.ec2.internal` is the instance at `10.0.1.194` in our subnet (`10.0.1.0/24`). Each instance shows its own name.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
