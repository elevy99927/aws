# 5.02 Terraform Basic Commands – Lab 4 Solution

[⬅ Lab 4](../tf-lab-4.md) | [⬅ Back to 5.02 Terraform Basic Commands](../README.md)

The solution is the eight files in this folder. Five come from Lab 3, and three are new:

| File | What it holds |
|---|---|
| [`vars.tf`](vars.tf) | Lab 3's variables, and the new `MY_IP`: your public IP address as a `/32` range |
| [`provider.tf`](provider.tf) | The same as in Lab 3 |
| [`vpc.tf`](vpc.tf) | The VPC and the subnet, now with `map_public_ip_on_launch = true`, and the internet gateway `training-igw`, the route table `training-public-rt` and its association |
| [`security.tf`](security.tf) **new** | The security group `training-ssh`: SSH (port 22) only from `var.MY_IP`, and all outbound traffic |
| [`key.tf`](key.tf) **new** | The key pair `tf-lab-key`, from `my-ssh-key.pub` |
| [`instance.tf`](instance.tf) | The two instances, now with the security group, the key pair, `depends_on` the internet gateway, and a `local-exec` provisioner |
| [`outputs.tf`](outputs.tf) **new** | `web_1_public_ip` and `web_2_public_ip` |
| [`s3.tf`](s3.tf) | The same as in Lab 3: replace `yourname-1234` with your own name and number |

The SSH key files, `my-ssh-key` and `my-ssh-key.pub`, aren't in this folder: you create your own in step 2, and never commit them.

## Steps 2–3: the SSH key and the key pair

```bash
ssh-keygen -t ed25519 -f my-ssh-key -N ""
```

```hcl
resource "aws_key_pair" "lab" {
  key_name   = "tf-lab-key"
  public_key = file("my-ssh-key.pub")
}
```

The [`aws_key_pair`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) Example Usage pastes the public key as text. `file()`, a built-in function, reads it from the file instead.

## Steps 4–6: a way in from the internet

At the end of Lab 3, four things were missing. This lab adds all of them:

- **A public IP address:** `map_public_ip_on_launch = true` on the subnet gives new instances a public IPv4 address by default.
- **An internet gateway and a route:** `training-public-rt` sends traffic to the internet (`0.0.0.0/0`) to `training-igw`. Traffic inside the VPC still uses the local route. The association connects the subnet to this route table; without it, the subnet keeps the VPC's main route table, which has no way out.
- **A security group:** `training-ssh` allows SSH only from `var.MY_IP`, and all outbound traffic.
- **A key pair:** `tf-lab-key`.

Set your IP address from the shell, the `TF_VAR_` way from Lab 2:

```bash
export TF_VAR_MY_IP="$(curl -s https://checkip.amazonaws.com)/32"                     # macOS and Linux
$env:TF_VAR_MY_IP = "$((Invoke-RestMethod https://checkip.amazonaws.com).Trim())/32"   # Windows PowerShell
```

## Step 7: the instances

```hcl
resource "aws_instance" "web_1" {
  ami                    = var.AMIS[var.AWS_REGION]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_1a.id
  vpc_security_group_ids = [aws_security_group.ssh.id]
  key_name               = aws_key_pair.lab.key_name

  tags = {
    Name = "my-tf-web-1"
  }

  depends_on = [aws_internet_gateway.main]

  provisioner "local-exec" {
    command = "echo ${self.tags.Name} ${self.public_ip} >> LAB-IPS.txt"
  }
}
```

- `self` is the resource the provisioner belongs to, so `self.public_ip` is this instance's public IP address.
- `depends_on`: the instances don't refer to the internet gateway, so you set the order yourself. Terraform creates the gateway first, and on destroy, removes it after the instances. The [`aws_internet_gateway`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) page recommends this for instances with public IPs.

## Step 8: the outputs

```hcl
output "web_1_public_ip" {
  value = aws_instance.web_1.public_ip
}
```

`public_ip` is in the **Attribute Reference** of [`aws_instance`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#attribute-reference). (`public_dns` is empty here: it needs DNS hostnames enabled on the VPC.)

## Steps 9–10: plan and apply

The real run, from a clean account. The IP addresses and IDs are masked:

```text
Plan: 12 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_1_public_ip = (known after apply)
  + web_2_public_ip = (known after apply)
```

```text
aws_instance.web_2: Provisioning with 'local-exec'...
aws_instance.web_2 (local-exec): Executing: ["/bin/sh" "-c" "echo my-tf-web-2 203.0.113.11 >> LAB-IPS.txt"]
aws_instance.web_1: Provisioning with 'local-exec'...
aws_instance.web_1 (local-exec): Executing: ["/bin/sh" "-c" "echo my-tf-web-1 203.0.113.12 >> LAB-IPS.txt"]
...
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

web_1_public_ip = "203.0.113.12"
web_2_public_ip = "203.0.113.11"
```

- **12 to add:** the five resources from Lab 3, and seven new ones: the internet gateway, the route table, its association, the security group, its two rules, and the key pair.
- **If you kept the resources from Lab 3,** the plan instead adds the seven new ones, changes the subnet in place, and replaces the two instances: changing `key_name` forces new instances, so anything stored on the old ones is lost.
- On Windows, `local-exec` runs the command with `cmd.exe`, and `echo … >> LAB-IPS.txt` works the same way.

## Steps 11–12: the IP addresses, and SSH

```text
$ cat LAB-IPS.txt
my-tf-web-2 203.0.113.11
my-tf-web-1 203.0.113.12

$ terraform output
web_1_public_ip = "203.0.113.12"
web_2_public_ip = "203.0.113.11"

$ ssh -i my-ssh-key ec2-user@203.0.113.12
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
...
   ,     #_
   ~\_  ####_        Amazon Linux 2023
...
[ec2-user@ip-10-0-1-33 ~]$
```

- `ec2-user` is the default user on Amazon Linux.
- Newer SSH clients may print a warning about a post-quantum key exchange. It's about the server's SSH version, and you can ignore it in this lab.
- **SSH times out?** Wait a minute after `apply`. If it still times out, check that your public IP address hasn't changed since you set `TF_VAR_MY_IP`: some networks use more than one. Set it again, and run `terraform apply` to update the rule.

## Step 13: clean up

```text
Plan: 0 to add, 0 to change, 12 to destroy.
...
Destroy complete! Resources: 12 destroyed.
```

The internet gateway is destroyed after the instances (the `depends_on`), and the VPC last. `LAB-IPS.txt`, `my-ssh-key` and `my-ssh-key.pub` stay in the folder.

## Answers

1. **`local-exec`** runs on your computer, where you run `terraform apply`. **`remote-exec`** and **`file`** run on the new instance: Terraform connects to it over SSH, with a `connection` block.
2. **`(known after apply)`:** the instances don't exist yet when Terraform plans. AWS gives each one its public IP address only when it launches it.
3. **The instances are replaced** because `key_name` can't change on an existing instance: changing it forces a new one.
4. **No new lines:** provisioners run only when Terraform creates a resource. With no changes, nothing is created, so `local-exec` doesn't run. If an instance is replaced, its new line is added to the file, and the old line stays.
5. **`LAB-IPS.txt` stays** because Terraform doesn't manage it: `local-exec` wrote it, but it isn't a resource in the state file, so `destroy` doesn't know about it.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
