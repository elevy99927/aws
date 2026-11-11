# 5.02 Terraform Basic Commands – Lab 7 Solution

[⬅ Lab 7](../tf-lab-7.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the Lab 6 folder with one file renamed and one changed:

| File | What it holds |
|---|---|
| [`install-nginx.sh.tftpl`](install-nginx.sh.tftpl) **renamed** | The user-data script as a template: `${server_name}` and `${bucket}` in the page it writes |
| [`instance.tf`](instance.tf) | Both instances: `user_data = templatefile("install-nginx.sh.tftpl", { server_name = "web-1", bucket = aws_s3_bucket.lab.bucket })`, and `web-2` for the second |
| [`backend.tf`](backend.tf), [`security.tf`](security.tf), [`outputs.tf`](outputs.tf), [`vars.tf`](vars.tf), [`provider.tf`](provider.tf), [`vpc.tf`](vpc.tf), [`key.tf`](key.tf), [`s3.tf`](s3.tf) | The same as in Lab 6 |

Replace `tfstate-<yourname>-<number>` in `backend.tf` with your state bucket, and `s3-lab-yourname-1234` in `s3.tf` with your Lab 3 bucket. Your SSH key files, `my-ssh-key` and `my-ssh-key.pub`, come from your Lab 4 folder.

## The template

```bash
#!/bin/bash
dnf install -y nginx
cat > /usr/share/nginx/html/index.html <<HTML
<h1>Hello from ${server_name}</h1>
<p>Installed by user-data on $(hostname)</p>
<p>Our bucket: ${bucket}</p>
HTML
systemctl enable --now nginx
```

- Terraform replaces only `${...}`. `$(hostname)` has no braces, so it reaches the shell untouched and runs on the instance.
- Every `${...}` is replaced, even inside a comment: a comment like `# fills in ${server_name}` would come out as `# fills in web-1`. To write a literal `${`, double the dollar sign: `$${`.

```hcl
resource "aws_instance" "web_1" {
  # ... as in Lab 6 ...
  user_data = templatefile("install-nginx.sh.tftpl", {
    server_name = "web-1"
    bucket      = aws_s3_bucket.lab.bucket
  })
  user_data_replace_on_change = true
}
```

## The real run

IDs and IP addresses are masked. Terraform 1.15 prints a deprecation warning for `dynamodb_table` on every command; it's left out below.

**`terraform console`**, with made-up values, shows what the function returns: the whole script, filled in.

```text
$ terraform console
> templatefile("install-nginx.sh.tftpl", { server_name = "test", bucket = "my-bucket" })
<<EOT
#!/bin/bash
dnf install -y nginx
cat > /usr/share/nginx/html/index.html <<HTML
<h1>Hello from test</h1>
<p>Installed by user-data on $(hostname)</p>
<p>Our bucket: my-bucket</p>
HTML
systemctl enable --now nginx

EOT
```

**The plan:** the user data changed, so both instances are replaced. The diff shows each instance's own values.

```text
  # aws_instance.web_1 must be replaced
      ~ user_data                            = <<-EOT # forces replacement
          + <h1>Hello from web-1</h1>
          + <p>Our bucket: s3-lab-student-2823</p>
  # aws_instance.web_2 must be replaced
      ~ user_data                            = <<-EOT # forces replacement
          + <h1>Hello from web-2</h1>
          + <p>Our bucket: s3-lab-student-2823</p>

Plan: 2 to add, 0 to change, 2 to destroy.
```

**The apply:** `remote-exec` prints each page, with its own name and the bucket.

```text
aws_instance.web_1 (remote-exec): <h1>Hello from web-1</h1>
aws_instance.web_1 (remote-exec): <p>Installed by user-data on ip-10-0-1-211.ec2.internal</p>
aws_instance.web_1 (remote-exec): <p>Our bucket: s3-lab-student-2823</p>
...
aws_instance.web_2 (remote-exec): <h1>Hello from web-2</h1>
aws_instance.web_2 (remote-exec): <p>Installed by user-data on ip-10-0-1-67.ec2.internal</p>
aws_instance.web_2 (remote-exec): <p>Our bucket: s3-lab-student-2823</p>

Apply complete! Resources: 2 added, 0 changed, 2 destroyed.

Outputs:

web_1_url = "http://203.0.113.11"
web_2_url = "http://203.0.113.12"
```

```text
$ curl http://203.0.113.11
<h1>Hello from web-1</h1>
<p>Installed by user-data on ip-10-0-1-211.ec2.internal</p>
<p>Our bucket: s3-lab-student-2823</p>
$ curl http://203.0.113.12
<h1>Hello from web-2</h1>
<p>Installed by user-data on ip-10-0-1-67.ec2.internal</p>
<p>Our bucket: s3-lab-student-2823</p>
```

## Clean up

```text
$ terraform destroy
Plan: 0 to add, 0 to change, 13 to destroy.
Destroy complete! Resources: 13 destroyed.
```

The state bucket and the lock table stay for the next labs.

## Answers

1. **`templatefile()` returns a string:** the file's text with every `${name}` replaced by the value from the map. Terraform runs it on your computer while it builds the plan, when all the values are known (as here: the bucket exists). If a value is known only after apply, like a new database's IP, the plan shows `(known after apply)` and Terraform renders the script after creating that resource, before creating the instance. Either way, the instance receives the finished script as its user data.
2. **`${...}` belongs to Terraform.** `$(hostname)`, `$HOME` or `$1` have no `${`, so Terraform leaves them for the shell. A literal `${` is written `$${`.
3. **A different `server_name` means different user data,** and `user_data_replace_on_change = true` (from Lab 6) turns a user-data change into a replacement, because user data runs only at the first boot.
4. **`aws_s3_bucket.lab.bucket` makes the instance depend on the bucket:** Terraform must know the bucket's name before it can render the script, so it creates (or reads) the bucket first. In this lab the bucket already exists, so nothing changes in the order; with a new bucket, the instances would wait for it.
5. **Anywhere text needs values from Terraform:** a config file copied with the `file` provisioner, a systemd unit, an nginx or application config with a database address, an IAM policy document, or a Kubernetes manifest. In the course slides, the classic example is a web server's config that gets the database's private IP.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
