# Floci – Lab 1 Solution

[⬅ Lab 1](../floci-lab-1.md) | [⬅ Back to Floci](../README.md)

The solution is a Terraform configuration the course already knows (a VPC with a public subnet, a security group for SSH, a key pair, two instances and an S3 bucket), adapted for Floci:

| File | What it holds |
|---|---|
| [`provider.tf`](provider.tf) | `endpoints` for `ec2`, `s3` and `sts` on `http://localhost:4566`, `s3_use_path_style`, the `skip_*` settings, credentials `test`/`test` |
| [`vars.tf`](vars.tf) | `AMIS` is one entry, `ami-amazonlinux2023`; `MY_IP` defaults to `0.0.0.0/0` |
| [`instance.tf`](instance.tf) | two instances in the subnet, with the key pair and the SSH security group; `local-exec` writes their names and IPs to `LAB-IPS.txt` |
| [`outputs.tf`](outputs.tf) | each instance's public IP (`127.0.0.1` on Floci) and id (the name of its container in `docker ps`) |
| [`key.tf`](key.tf) | the key pair, from `ssh/terraform-key.pub` |
| [`generate_ssh_key.sh`](generate_ssh_key.sh) | makes `ssh/terraform-key` and `ssh/terraform-key.pub` with `ssh-keygen` |
| [`vpc.tf`](vpc.tf), [`security.tf`](security.tf), [`s3.tf`](s3.tf) | the VPC, subnet, internet gateway and route table; SSH in and everything out; the bucket `s3-lab-floci-1234` |

No backend: the state stays in the lab folder, `terraform.tfstate`.

The terminal blocks below are from the real run on a Mac with Docker Desktop (Apple Silicon). Nothing in them is masked: there is no account, no real IP and no real ID in a Floci run.

## Part 1: start Floci

```text
$ docker start floci 2>/dev/null || docker run -d --name floci -p 4566:4566 -v /var/run/docker.sock:/var/run/docker.sock -u root floci/floci:latest
891271fd37e675b339d6518086f06da7439f1e7af657423bdf5d9292e381ace9
$ curl -s http://localhost:4566/_floci/health | head -c 120
{"edition":"community","services":{"ssm":"running","sqs":"running","s3":"running","dynamodb":"running","sns":"running"

$ export AWS_ENDPOINT_URL=http://localhost:4566 AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
$ aws s3 ls
$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-default-us-east-1	172.31.0.0/16
```

- With no `floci` container yet, `docker start` fails silently and `docker run` creates it (the long id). With a container left from a previous run, `docker start` restarts it and prints `floci`.
- Floci answers in about a second. The health page lists every service and its state.

## Part 2: the Terraform configuration, on Floci

```text
$ ./generate_ssh_key.sh
Generating public/private rsa key pair.
Your identification has been saved in ./ssh/terraform-key
Your public key has been saved in ./ssh/terraform-key.pub
...
SSH key pair generated at ./ssh/terraform-key and ./ssh/terraform-key.pub

$ terraform init
...
Terraform has been successfully initialized!

$ terraform apply
...
Plan: 12 to add, 0 to change, 0 to destroy.

  Enter a value: yes

aws_vpc.main: Creating...
aws_key_pair.lab: Creating...
aws_s3_bucket.lab: Creating...
...
aws_instance.web_1: Creating...
aws_instance.web_2: Creating...
aws_instance.web_2: Creation complete after 10s [id=i-11f2a209a047119b6]
aws_instance.web_1: Creation complete after 10s [id=i-3c303f05413924286]

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

web_1_id = "i-3c303f05413924286"
web_1_public_ip = "127.0.0.1"
web_2_id = "i-11f2a209a047119b6"
web_2_public_ip = "127.0.0.1"
```

- 12 resources: the VPC, the subnet, the internet gateway, the route table and its association, the security group and its two rules, the key pair, the bucket and the two instances. The whole apply takes about 15 seconds: an instance is a `docker run` plus the SSH key injection (10 s).
- `127.0.0.1` is Floci's answer for a public IP on Docker Desktop, where container addresses can't be reached from the host; SSH is reached through a published port instead.

## Part 3: SSH into an instance

```text
$ docker ps --format "table {{.Names}}\t{{.Ports}}"
NAMES                               PORTS
floci-aws-ec2-i-11f2a209a047119b6   0.0.0.0:2201->22/tcp, [::]:2201->22/tcp
floci-aws-ec2-i-3c303f05413924286   0.0.0.0:2200->22/tcp, [::]:2200->22/tcp
floci                               0.0.0.0:4566->4566/tcp, [::]:4566->4566/tcp
```

`web_1` is `i-3c303f05413924286`, so its SSH is on port 2200:

```text
$ ssh -i ssh/terraform-key -p 2200 root@localhost
Warning: Permanently added '[localhost]:2200' (ED25519) to the list of known hosts.
[root@56a447d12f92 ~]# whoami
root
[root@56a447d12f92 ~]# grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Amazon Linux 2023.12.20261102"
[root@56a447d12f92 ~]# echo $HOSTNAME
56a447d12f92
[root@56a447d12f92 ~]# cat ~/.ssh/authorized_keys | cut -c1-40
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+
[root@56a447d12f92 ~]# TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "x-aws-ec2-metadata-token-ttl-seconds: 60")
[root@56a447d12f92 ~]# curl -s -H "x-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
i-3c303f05413924286
[root@56a447d12f92 ~]# curl -s -H "x-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4
10.0.1.11
[root@56a447d12f92 ~]# systemctl status
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
[root@56a447d12f92 ~]# exit
logout
Connection to localhost closed.
```

- The SSH server answered about 45 seconds after the apply in this run: Floci installs OpenSSH in the container after it starts. Until then, `ssh` says "Connection refused".
- Recent OpenSSH clients (10.x) also print a warning that the connection "is not using a post-quantum key exchange algorithm". It comes from your client, not from the lab, and is harmless here.
- The host name is the container's id. The metadata service answers with the instance id from the outputs and its private address in `10.0.1.0/24`: Floci creates a Docker network for the VPC and hands out addresses from the subnet.
- No systemd: a container's first process is not an init system, so services are started directly.

## The AWS CLI

```text
$ aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,Tags[?Key=='Name']|[0].Value]" --output table
-----------------------------------------------------------------------------
|                             DescribeInstances                             |
+----------------------+----------+------------+------------+---------------+
|  i-11f2a209a047119b6 |  running |  127.0.0.1 |  10.0.1.10 |  my-tf-web-2  |
|  i-3c303f05413924286 |  running |  127.0.0.1 |  10.0.1.11 |  my-tf-web-1  |
+----------------------+----------+------------+------------+---------------+
$ aws ec2 describe-key-pairs --query "KeyPairs[].KeyName" --output text
tf-lab-key
$ aws s3 ls
2026-11-06 13:44:23 s3-lab-floci-1234
```

## Clean up

```text
$ terraform destroy
...
Plan: 0 to add, 0 to change, 12 to destroy.

  Enter a value: yes
...
Destroy complete! Resources: 12 destroyed.

$ docker ps --format "{{.Names}}" | grep floci
floci-aws-ec2-volume-helper
floci
$ docker stop floci
floci
```

The instance containers are gone with the destroy. `docker stop floci` stops the emulator; it keeps everything in memory, so the next `docker start floci` begins with an empty account (the Floci CLI's `floci start --persist ./data` keeps data across restarts, if you ever need that).

## Floci-specific things worth remembering

- **SSH is on a host port** (2200, 2201, …), as **root**, with the key pair's private key: `ssh -i ssh/terraform-key -p 2200 root@localhost`. The port isn't in any AWS API: read it from `docker ps`.
- **An instance is a container:** no systemd, no cloud-init, a small image (`hostname` isn't installed in `amazonlinux:2023`; `$HOSTNAME` is set).
- **Port 80 inside an instance is taken** by Floci's metadata proxy (`169.254.169.254:80`): a web server must listen on another port. Lab 2 runs into this.
- **Security group CIDRs are not enforced,** and the public IP is `127.0.0.1`: Floci publishes the ports for anyone on the computer.

## Answers

1. **Without `endpoints`, the provider talks to the real AWS**: `ec2.us-east-1.amazonaws.com` and the others. With the `test` credentials the calls fail with an authentication error; with your real session they would create real resources, and bill them. Every service the configuration uses needs an endpoint on Floci.
2. **2200 is a host port Floci chose** (from `2200–2299`) and published for the instance container's port 22, because on Docker Desktop the container's own address isn't reachable from the computer. `127.0.0.1` is the public IP Floci reports in that case. The port isn't part of any AWS answer: `docker ps` shows it.
3. **Floci injects the key into `/root/.ssh/authorized_keys`**, so you log in as `root`. On AWS, the Amazon Linux AMI's cloud-init puts the key pair into the `ec2-user` account, and root login over SSH is disabled.
4. **On AWS and not on Floci**, for example: the security group's CIDR really blocks other addresses; the instance has a real public IP, port 22 on it, a kernel, systemd and cloud-init; the AMI id must exist in the Region; resources cost money and count against quotas; `terraform apply` takes minutes; a bucket name must be unique in the world.
5. **The state is local**, `terraform.tfstate` in the lab folder. The resources it describes live only in the `floci` container's memory: after `docker stop floci` and a new start, the account is empty, while the state file still lists the old resources. So `terraform destroy` first, then stop Floci; if you forgot, delete the state file before the next `apply`.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
