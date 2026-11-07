# 5.02 Terraform Basic Commands – Lab 7: Templates

[⬅ Lab 6](tf-lab-6.md) | [⬅ Back to 5.02 Terraform Basic Commands](README.md) | [Solution ➡](tf-lab-7-solution/README.md)

[![Video: Terraform – Templates](https://img.youtube.com/vi/1fkFnuseZcI/maxresdefault.jpg)](https://youtu.be/1fkFnuseZcI)

In Lab 6 you learned user data: a script that runs when the instance boots. But what if the script needs values that don't exist yet when you write it, like the IP address of a database server, or a user name and password? In this lab you turn the script into a **template**: the same file, with placeholders that Terraform fills in before the instance gets it. One value is a plain string (the server's name), and one comes from another resource (the name of the lab's S3 bucket). Each instance then gets its own script, and its page shows it.

## Templates

A template is a text file with placeholders. `templatefile(path, vars)` reads the file, replaces every `${name}` with the value from `vars`, and returns the result as a string: ready for `user_data`, a config file, or any other argument that takes text.

| | Written as | Example |
|---|---|---|
| Placeholder in the template | `${name}` | `echo "Hello from ${server_name}"` |
| The call in Terraform | `templatefile("file.tftpl", { name = value })` | `templatefile("install-nginx.sh.tftpl", { server_name = "web-1" })` |
| A value from a resource | any attribute | `bucket = aws_s3_bucket.lab.bucket` |

- The `.tftpl` ending is a convention that helps editors recognize a template; calling `templatefile()` is what renders it.
- A shell script also uses `$`: `$(hostname)` and `$HOME` have no `${`, so they pass through to the shell untouched. A literal `${` is written `$${`.
- Older code uses the `template` provider, `data "template_file"` with `template = file(...)` and `vars { ... }`, and `.rendered`. It's deprecated, and the provider has no build for Apple Silicon. `templatefile()` is built into Terraform and does the same job.

## What you add

| What | Settings |
|---|---|
| Template | `install-nginx.sh.tftpl`: the Lab 6 script, with `${server_name}` and `${bucket}` in the page it writes |
| Instances | `user_data = templatefile("install-nginx.sh.tftpl", { server_name = "web-1", bucket = aws_s3_bucket.lab.bucket })`, and `web-2` for the second |

Region: **`us-east-1`**.

Before you start:
- [Lab 6](tf-lab-6.md): this lab continues from its folder, `tf-lab-6`, with the state in S3, the SSH key and `TF_VAR_MY_IP`.

> 💰 **Cost:** two small instances and their public IPv4 addresses for the length of the lab cost a few cents.

## Steps

### Part 1: The template

1. **Copy the Lab 6 folder** to a new folder, and work there:
   ```bash
   cp -r tf-lab-6 tf-lab-7
   cd tf-lab-7
   terraform init
   ```
   - Set your IP address again if this is a new terminal: `export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"`.
   - If you destroyed the Lab 6 resources, run `terraform apply` once now.
2. **Turn the script into a template.** Rename `install-nginx.sh` to `install-nginx.sh.tftpl`, and make the page it writes use two placeholders:
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
   - `${server_name}` and `${bucket}` are filled in by Terraform. `$(hostname)` stays for the shell: Terraform fills in `${...}`, and leaves a plain `$` alone.
3. **Try it in `terraform console`:**
   ```hcl
   templatefile("install-nginx.sh.tftpl", { server_name = "test", bucket = "my-bucket" })
   ```
   - The result is the whole script, with your values in place. Exit with `exit`.

### Part 2: One script per instance

4. **Fill the template** in `instance.tf`. In both instances, replace `user_data = file("install-nginx.sh")` with:
   ```hcl
   user_data = templatefile("install-nginx.sh.tftpl", {
     server_name = "web-1"
     bucket      = aws_s3_bucket.lab.bucket
   })
   ```
   and `server_name = "web-2"` in the second instance.
   - `aws_s3_bucket.lab.bucket` is the name of the bucket from Lab 3: a value that comes from another resource, which is exactly what a template is for. Here the bucket already exists, so the plan shows the finished script; for a value that doesn't exist yet (a new database's IP), the plan shows `(known after apply)` and Terraform fills it in after creating the database.
5. **Run `terraform plan`.** Read it:
   - why are both instances replaced?
   - find your name and the bucket in the new `user_data`.
6. **Run `terraform apply`**, and type `yes`. The `remote-exec` lines print each page: `Hello from web-1`, then `Hello from web-2`.
7. **Open the pages:** `curl` each URL from `terraform output`. Each page shows its own name and the bucket.
8. **Clean up:** run `terraform destroy`, and type `yes`.
   - Keep the state bucket and the lock table for the next labs.

## Questions

1. What does `templatefile()` return, and when does Terraform run it?
2. In the template, `${server_name}` is for Terraform and `$(hostname)` is for the shell. How does Terraform tell them apart, and how would you write a literal `$`?
3. Why does changing `server_name` replace the instance?
4. The bucket name comes from `aws_s3_bucket.lab.bucket`. What does that mean for the order in which Terraform creates things?
5. Where else, besides user data, would a template be useful?

## What's next?

Compare your files and answers with the **[Solution](tf-lab-7-solution/README.md)**.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
