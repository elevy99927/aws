# Floci – Lab 1: AWS on Your Computer

[⬅ Back to Floci](README.md) | [Solution ➡](floci-lab-1-solution/README.md)

Until now, every `terraform apply` went to a real AWS account: minutes to wait, a few cents to pay, and resources that cost money until you remembered `destroy`. In this lab you set up **Floci**, an AWS emulator on your own computer, point the AWS CLI and Terraform at it, create a VPC with two EC2 instances, and connect to an instance with SSH. `apply` takes seconds, nothing is billed, and the instances are Docker containers on your computer.

## What Floci is

[Floci](https://floci.io/aws/) is a free, MIT-licensed emulator of AWS APIs. It runs as one Docker container that answers on `http://localhost:4566`, speaks the same protocols as AWS, and accepts any credentials. The AWS CLI, Terraform and every SDK work against it unchanged, apart from the endpoint. Today it covers 126 services, among them the ones this course uses: EC2 (VPCs, subnets, security groups, key pairs, instances), S3, DynamoDB, IAM, Lambda, ECS, RDS.

Some services are more than mocks: **an EC2 instance is a real Docker container**, started from an image that matches the AMI (Amazon Linux 2023 by default). SSH really works, S3 really stores objects, and the instance metadata service answers from inside the instance.

| | On AWS | On Floci |
|---|---|---|
| `terraform apply` of this configuration | 2–3 minutes | about 15 seconds |
| Cost | instances, public IPv4 addresses, requests: cents per hour, and a bill if you forget `destroy` | $0 |
| Credentials | your account, `aws login`, keys to protect | `test` / `test` |
| Internet | required | only to pull images |
| Leftovers | resources keep running until you delete them | `docker stop floci` and everything is gone |

**When to use it:**
- **Developing** Terraform, CLI scripts or application code that talks to AWS: iterate in seconds, then run once against the real account.
- **Learning and practising**: repeat a lab ten times without watching the bill.
- **Tests in CI**: a pipeline can start Floci, run your code against it, and stop it, with no cloud account on the build machine.

**What it isn't:** an emulator imitates the API, not the data center. Security group CIDRs are not enforced, instances are containers (no systemd, no cloud-init, no real kernel), there is no real routing between VPCs, and AWS quotas, prices and IAM edge cases are not reproduced. Code that passes on Floci still needs one run against AWS before production.

## What you need

| What | Settings |
|---|---|
| Floci | the `floci/floci:latest` container, port 4566, with the Docker socket mounted (it starts the instance containers) |
| Environment | `AWS_ENDPOINT_URL=http://localhost:4566`, credentials `test`/`test`, Region `us-east-1` |
| `provider.tf` | the `endpoints` block, `s3_use_path_style`, and the three `skip_*` settings |
| `vars.tf` | the AMI `ami-amazonlinux2023` (a Floci alias), `MY_IP` with a default |
| SSH key | `ssh/terraform-key`, made by `generate_ssh_key.sh` |

The state stays in the lab folder (`terraform.tfstate`): no backend in this lab.

Before you start, please complete the following
- The [Terraform tutorial](../5-terraform/5.02-terraform-basic-commands/README.md).
- Docker is running and `docker ps` works.
- The AWS CLI (v2) and Terraform are installed, as in [Getting Started](../00-getting-started/README.md) and [5.01](../5.01-install-terraform/README.md).

> 💰 **Cost:** nothing. No AWS account is used in this lab.

## Steps

### Part 1: Start Floci

1. **Start the emulator:**
   ```bash
   docker start floci 2>/dev/null || docker run -d --name floci -p 4566:4566 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -u root floci/floci:latest
   curl -s http://localhost:4566/_floci/health | head -c 120
   ```
   - If you already created the `floci` container before, you can just run `docker start floci`.
   - The Docker socket (`-v /var/run/docker.sock:...`) allows Floci to start a container for every EC2 instance.
   - The health check answers with the list of services and their state.


2. **Point the AWS CLI at your computer.** In the terminal you'll use for the whole lab:
   ```bash
   export AWS_ENDPOINT_URL=http://localhost:4566
   export AWS_ACCESS_KEY_ID=test
   export AWS_SECRET_ACCESS_KEY=test
   export AWS_DEFAULT_REGION=us-east-1
   aws s3 ls
   aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock]" --output text
   ```
   - `aws s3 ls` prints nothing: this "account" is empty. `describe-vpcs` shows Floci's default VPC, `172.31.0.0/16`, like a fresh AWS Region.
   - `AWS_ENDPOINT_URL` is read by the AWS CLI v2 and the SDKs, so no `--endpoint-url` on every command.
   - **Keep this terminal for Floci only.** A terminal without these variables talks to the real AWS.

### Part 2: The Terraform configuration, on Floci

3. **Get the files, and make the SSH key.** The configuration is in the course repo, [`floci/floci-lab-1-solution/`](floci-lab-1-solution/): a VPC with a public subnet, a security group for SSH, a key pair, two instances and an S3 bucket, already adapted for Floci (steps 4–5 explain the changes). Copy it, and make the key pair:
   ```bash
   cp -r <course repo>/floci/floci-lab-1-solution floci-lab-1
   cd floci-lab-1
   ./generate_ssh_key.sh
   ```
   - `generate_ssh_key.sh` runs `ssh-keygen` and writes `ssh/terraform-key` (the private key) and `ssh/terraform-key.pub` (the public key, which `key.tf` reads). Never commit the private key.
4. **The provider.** `provider.tf` talks to Floci:
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 6.0"
       }
     }
   }

   provider "aws" {
     region     = "us-east-1"
     access_key = "test"
     secret_key = "test"

     skip_credentials_validation = true
     skip_metadata_api_check     = true
     skip_requesting_account_id  = true
     s3_use_path_style           = true

     endpoints {
       ec2 = "http://localhost:4566"
       s3  = "http://localhost:4566"
       sts = "http://localhost:4566"
     }
   }
   ```
   - `endpoints` is the whole trick: every service the configuration uses gets the Floci address. A service you forget here goes to the real AWS.
   - `s3_use_path_style`: `http://localhost:4566/bucket/key` instead of `http://bucket.localhost:4566/key`, which no local DNS resolves.
   - The `skip_*` settings stop the provider from calling STS and the metadata service to check who you are: on Floci, `test` is everybody.
5. **The AMI and your IP.** In `vars.tf`, the `AMIS` map has one entry, and `MY_IP` has a default:
   ```hcl
   variable "AMIS" {
     type = map(string)
     default = {
       us-east-1 = "ami-amazonlinux2023"
     }
   }

   variable "MY_IP" {
     type    = string
     default = "0.0.0.0/0"
   }
   ```
   - Floci maps AMI ids to container images: `ami-amazonlinux2023` is `amazonlinux:2023`, `ami-ubuntu2404` is Ubuntu, and any id it doesn't know (a real `ami-0123…`) falls back to Amazon Linux 2023. So a real AWS id would work too; the alias says what you get.
   - Security group CIDRs are not enforced in this setup (Floci has an optional enforcement mode, off by default), so `MY_IP` no longer matters; the default saves the `export`.
6. **Init and apply:**
   ```bash
   terraform init
   terraform apply
   ```
   - Type `yes`: **12 to add**, and `Apply complete` in about 15 seconds.
   - The outputs show each instance's id, and `127.0.0.1` as its public IP: on Docker Desktop, container addresses aren't reachable from the host, so Floci publishes the ports instead (next part).

### Part 3: SSH into an instance

7. **The instances are containers:**
   ```bash
   docker ps --format "table {{.Names}}\t{{.Ports}}"
   ```
   - `floci-aws-ec2-i-…`: one container per instance, named after the instance id from the outputs. Port 22 of each is published on its own host port, from `2200` up; `web_1` doesn't always get `2200`.
8. **Connect.** Find the port next to the instance id of `web_1` (`terraform output web_1_id`); in our run it was `2200`:
   ```bash
   ssh -i ssh/terraform-key -p 2200 root@localhost
   ```
   - The user is **`root`**: Floci puts the key pair's public key in `/root/.ssh/authorized_keys`. (On AWS, Amazon Linux uses `ec2-user`.)
   - The first time, answer `yes` to the host key question. If the connection is refused, wait and try again: Floci installs the SSH server in the container after it starts; in our run SSH was ready about 45 seconds after the apply.
   - If you connected to `localhost:2200` before, from an older lab run, `ssh-keygen -R "[localhost]:2200"` clears the old host key.
9. **Look around.** Inside the instance:
   ```bash
   whoami
   grep PRETTY_NAME /etc/os-release
   echo $HOSTNAME
   TOKEN=$(curl -s -X PUT http://169.254.169.254/latest/api/token -H "x-aws-ec2-metadata-token-ttl-seconds: 60")
   curl -s -H "x-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id
   curl -s -H "x-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4
   systemctl status
   exit
   ```
   - `root`, Amazon Linux 2023, and a host name that is the container's id.
   - The metadata service answers as on AWS (IMDSv2: a token first, then the request): the instance id from the outputs, and a private address from the subnet, `10.0.1.0/24`.
   - `systemctl` fails: this container doesn't run systemd. Start services directly, as you'll see in Lab 2.
10. **The AWS CLI sees it all:**
    ```bash
    aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress,Tags[?Key=='Name']|[0].Value]" --output table
    aws ec2 describe-key-pairs --query "KeyPairs[].KeyName" --output text
    aws s3 ls
    ```
    - Two running instances with private addresses from the subnet, the key pair, and the lab's bucket: the same picture as on AWS.
11. **Clean up:** `terraform destroy` and `yes`: **12 to destroy**, done in seconds. `docker ps` shows no instance containers any more (a small `floci-aws-ec2-volume-helper` stays).
    - `docker stop floci` stops the emulator. Floci keeps everything **in memory**: the next `docker start floci` begins with an empty account. That's fine for a lab; for data that should survive a restart, the Floci CLI has `floci start --persist ./data`.

## Questions

1. On AWS, `provider.tf` has no `endpoints` block and works. What happens on Floci if you leave it out?
2. The apply prints `127.0.0.1` as the public IP, but you connect to `localhost` on port 2200. Where does 2200 come from, and why not port 22?
3. Why do you log in as `root` here, and as `ec2-user` on an Amazon Linux instance on AWS?
4. You run the same `terraform apply` on Floci and on AWS. Name three things that are true on AWS and not on Floci.
5. Where is the state in this lab, and what happens to the instances when you `docker stop floci`?

## What's next?

Compare your files and answers with the **[Solution](floci-lab-1-solution/README.md)**. Then continue to **Lab 2**, where we'll see how to work with user data in Floci.

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927/aws](https://github.com/elevy99927/aws)
